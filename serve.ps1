# Simple static file server on raw sockets (no admin rights needed).
# Serves the game at http://localhost:8123/ and http://<LAN-IP>:8123/
$root = $PSScriptRoot
$port = 8123
$types = @{
  ".html"="text/html; charset=utf-8"; ".js"="text/javascript; charset=utf-8"
  ".css"="text/css; charset=utf-8"; ".png"="image/png"; ".jpg"="image/jpeg"
  ".jpeg"="image/jpeg"; ".gif"="image/gif"; ".svg"="image/svg+xml"; ".ico"="image/x-icon"
}
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $port)
$listener.Start()
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
  Select-Object -First 1).IPAddress
Write-Host "Serving $root"
Write-Host "PC:    http://localhost:$port/"
if ($ip) { Write-Host "Phone: http://${ip}:$port/" }

function Send-Response($client, $status, $reason, $ctype, $bytes) {
  $w = New-Object System.IO.StreamWriter($client.GetStream(), [Text.Encoding]::ASCII, 1024, $true)
  $w.NewLine = "`r`n"
  $w.Write("HTTP/1.1 $status $reason`r`n")
  $w.Write("Content-Type: $ctype`r`n")
  $w.Write("Content-Length: $($bytes.Length)`r`n")
  $w.Write("Connection: close`r`n")
  $w.Write("Cache-Control: no-cache`r`n")
  $w.Write("`r`n")
  $w.Flush()
  $s = $client.GetStream()
  $s.Write($bytes, 0, $bytes.Length)
  $s.Flush()
  $w.Dispose()
}

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $client.ReceiveTimeout = 5000
    $client.SendTimeout = 5000
    $s = $client.GetStream()
    # read request headers
    $buf = New-Object byte[] 8192
    $total = 0
    $req = ""
    while ($total -lt 8192 -and -not $req.Contains("`r`n`r`n")) {
      $n = $s.Read($buf, 0, $buf.Length)
      if ($n -le 0) { break }
      $req += [Text.Encoding]::ASCII.GetString($buf, 0, $n)
      $total += $n
    }
    if ($req -match '^(GET|HEAD)\s+(\S+)\s+HTTP') {
      $method = $Matches[1]
      $rawPath = [Uri]::UnescapeDataString(($Matches[2] -split '\?')[0])
      $peer = $client.Client.RemoteEndPoint
      Write-Host "REQ $method $rawPath from $peer"
      if ($rawPath -eq "/" -or $rawPath -eq "") { $rawPath = "/index.html" }
      $full = [IO.Path]::GetFullPath((Join-Path $root $rawPath.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)))
      $rootFull = [IO.Path]::GetFullPath($root)
      if ($full.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path $full -PathType Leaf)) {
        $bytes = [IO.File]::ReadAllBytes($full)
        $ext = [IO.Path]::GetExtension($full).ToLower()
        $ctype = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
        if ($method -eq "HEAD") { $bytes = New-Object byte[] 0 }
        Send-Response $client 200 "OK" $ctype $bytes
      } else {
        Send-Response $client 404 "Not Found" "text/plain; charset=utf-8" ([Text.Encoding]::UTF8.GetBytes("not found"))
      }
    } else {
      Send-Response $client 400 "Bad Request" "text/plain" ([Text.Encoding]::ASCII.GetBytes("bad request"))
    }
  } catch {
    Write-Host "err: $($_.Exception.Message)"
  } finally {
    if ($client) { try { $client.Close() } catch {} }
  }
}
