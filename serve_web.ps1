$port = 8081
$webRoot = Join-Path $PSScriptRoot "build\web"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")

try {
    $listener.Start()
} catch {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:8082/")
    $listener.Prefixes.Add("http://127.0.0.1:8082/")
    $listener.Start()
    $port = 8082
}

Write-Host "PropZen Live Server started on http://localhost:$port"

$mimeTypes = @{
    ".html" = "text/html";
    ".css"  = "text/css";
    ".js"   = "application/javascript";
    ".json" = "application/json";
    ".png"  = "image/png";
    ".jpg"  = "image/jpeg";
    ".jpeg" = "image/jpeg";
    ".svg"  = "image/svg+xml";
    ".ico"  = "image/x-icon";
    ".wasm" = "application/wasm";
    ".ttf"  = "font/ttf";
    ".otf"  = "font/otf";
    ".woff" = "font/woff";
    ".woff2"= "font/woff2";
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($urlPath)) {
            $urlPath = "index.html"
        }

        # Clean query string / decode URL
        $urlPath = [System.Uri]::UnescapeDataString($urlPath)

        $filePath = Join-Path $webRoot $urlPath
        if (-not (Test-Path $filePath -PathType Leaf)) {
            $filePath = Join-Path $webRoot "index.html"
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = $mimeTypes[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.LongLength
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            $response.StatusCode = 200

            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.OutputStream.Flush()
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    } catch {
        # Catch and continue loop
    }
}
