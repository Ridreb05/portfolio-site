# Simple PowerShell HTTP server for local development
# Run this script, then open http://localhost:8080 in your browser

$port = 8080
$root = $PSScriptRoot   # directory containing this script

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host ""
Write-Host "  Dev Sanctuary — Local Server" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Running at: http://localhost:$port" -ForegroundColor Green
Write-Host "  Serving:    $root" -ForegroundColor DarkGray
Write-Host "  Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

# Open browser automatically
Start-Process "http://localhost:$port"

$mimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.webp' = 'image/webp'
    '.svg'  = 'image/svg+xml'
    '.ico'  = 'image/x-icon'
    '.woff2'= 'font/woff2'
}

while ($listener.IsListening) {
    try {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        $path = $req.Url.LocalPath -replace '/', [System.IO.Path]::DirectorySeparatorChar
        if ($path -eq '\') { $path = '\index.html' }
        $full = Join-Path $root $path.TrimStart('\')

        if (Test-Path $full -PathType Leaf) {
            $ext  = [System.IO.Path]::GetExtension($full).ToLower()
            $mime = $mimeTypes[$ext]
            if (-not $mime) { $mime = 'application/octet-stream' }

            $bytes = [System.IO.File]::ReadAllBytes($full)
            $resp.ContentType   = $mime
            $resp.ContentLength64 = $bytes.Length
            $resp.StatusCode    = 200
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $resp.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
            $resp.ContentType = 'text/plain; charset=utf-8'
            $resp.ContentLength64 = $msg.Length
            $resp.OutputStream.Write($msg, 0, $msg.Length)
        }

        $resp.OutputStream.Close()
    } catch {
        # Ctrl+C causes a clean exit here
        break
    }
}

$listener.Stop()
Write-Host "Server stopped." -ForegroundColor Yellow
