param(
  [Parameter(Mandatory=$true)][string]$Url,
  [Parameter(Mandatory=$true)][string]$Out,
  [int]$Budget = 7000,
  [int]$Tries = 3,
  [int]$Timeout = 100,
  [string]$Size = '1280,800'
)
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
function Kill-Chrome {
  Get-CimInstance Win32_Process -Filter "Name='chrome.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'headless|chr_' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
for($i = 1; $i -le $Tries; $i++){
  Kill-Chrome
  Start-Sleep -Milliseconds 300
  if(Test-Path $Out){ Remove-Item $Out -Force -ErrorAction SilentlyContinue }
  $prof = Join-Path $env:TEMP ("shot_" + [guid]::NewGuid().ToString("N").Substring(0,8))
  $chrArgs = @('--headless=new','--no-sandbox','--disable-gpu','--enable-unsafe-swiftshader',
               "--user-data-dir=$prof",'--hide-scrollbars',"--window-size=$Size",
               "--virtual-time-budget=$Budget","--screenshot=$Out",$Url)
  $p = Start-Process -FilePath $chrome -ArgumentList $chrArgs -PassThru -WindowStyle Hidden
  $ok = $true
  try { Wait-Process -Id $p.Id -Timeout $Timeout -ErrorAction Stop } catch { $ok = $false }
  Kill-Chrome
  if($ok -and (Test-Path $Out) -and ((Get-Item $Out).Length -gt 8000)){
    Remove-Item $prof -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output ("OK try=$i size=" + (Get-Item $Out).Length)
    exit 0
  }
  Remove-Item $prof -Recurse -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
}
Write-Output "FAIL"
exit 1
