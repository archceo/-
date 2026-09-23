# Keeps the public tunnel to serveo.net alive.
# Reconnects automatically; prints the current public URL on every connect.
# URL changes on reconnect (free serveo accounts give random names).
$ssh = "C:\WINDOWS\System32\OpenSSH\ssh.exe"
while ($true) {
  Write-Host "=== tunnel connect attempt $(Get-Date -Format 'HH:mm:ss') ==="
  & $ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -o ConnectTimeout=15 -R 80:127.0.0.1:8123 serveo.net
  Write-Host "=== tunnel dropped (exit=$LASTEXITCODE), retry in 5s ==="
  Start-Sleep -Seconds 5
}
