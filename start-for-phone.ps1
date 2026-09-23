# Start the game for phone access: double-click -> "Yes" in UAC prompt.
# Opens firewall port 8123 and runs the server on all interfaces.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`""
  exit
}
if (-not (Get-NetFirewallRule -DisplayName 'GeoQuest 8123' -ErrorAction SilentlyContinue)) {
  New-NetFirewallRule -DisplayName 'GeoQuest 8123' -Direction Inbound -Protocol TCP -LocalPort 8123 -Action Allow -Profile Any | Out-Null
  Write-Host "Firewall: port 8123 allowed."
}
& "$PSScriptRoot\serve.ps1"
