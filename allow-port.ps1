# Allows inbound connections to the game in Windows Firewall.
# Run: right-click -> "Run as administrator"
if (-not (Get-NetFirewallRule -DisplayName 'GeoQuest 8123' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -DisplayName 'GeoQuest 8123' -Direction Inbound -Protocol TCP -LocalPort 8123 -Action Allow -Profile Any | Out-Null
  Write-Host "Firewall rule 'GeoQuest 8123' added."
} else {
  Write-Host "Firewall rule 'GeoQuest 8123' already exists."
}
Write-Host "Now start serve.ps1 as administrator and open http://<PC-IP>:8123/ on your phone."
Start-Sleep -Seconds 3
