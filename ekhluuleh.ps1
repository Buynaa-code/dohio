# Гарын дохио таних хуудсыг localhost дээр нээнэ.
# Ашиглах: энэ файл дээр баруун товч → "Run with PowerShell"
# Зогсоох: энэ цонхонд Ctrl+C дарна.

$port = 8777
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$types = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.mjs'  = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.wasm' = 'application/wasm'
  '.task' = 'application/octet-stream'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() }
catch { Write-Host "Порт $port завгүй байна. Өөр програм ажиллаж байж магадгүй." -Foreground Red; Read-Host; exit 1 }

$url = "http://localhost:$port/dohio.html"
Write-Host ""
Write-Host "  Сервер ажиллаж байна:  $url" -Foreground Green
Write-Host "  Зогсоох: Ctrl+C" -Foreground DarkGray
Write-Host ""
Start-Process $url

try {
  while ($listener.IsListening) {
    $ctx  = $listener.GetContext()
    $rel  = [Uri]::UnescapeDataString($ctx.Request.Url.LocalPath).TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'dohio.html' }
    $file = Join-Path $root $rel

    if ((Test-Path $file -PathType Leaf) -and $file.StartsWith($root)) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ctx.Response.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' })
      # хуучин хуудас кэшлэгдэхээс сэргийлнэ
      $ctx.Response.Headers.Add('Cache-Control', 'no-store, must-revalidate')
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  }
} finally {
  $listener.Stop()
}
