# Downloads the programs Hotcray runs on, into this folder:
#   bin\kanata.exe             kanata (Windows, keyboard hook build "winIOv2")
#   bin\kanata_wintercept.exe  kanata for the optional Interception driver
#   bin\kanata                 kanata (Linux), so one USB stick works on both
#   Hotcray.exe                AutoHotkey v2 (renamed: runs Hotcray.ahk)
#
# Usage (PowerShell, in the Hotcray folder):
#   powershell -ExecutionPolicy Bypass -File .\get-binaries.ps1
#
# Every download is checked against a known SHA-256 hash, so a tampered or
# corrupted file is never used. To upgrade kanata/AutoHotkey, change the
# versions AND hashes below (hashes: the release's "sha256sums" file).
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # makes Invoke-WebRequest much faster
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$KanataVersion = 'v1.11.0'
$Downloads = @(
  @{ Url = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/windows-binaries-x64.zip"
     Sha = 'db43d06e7f8d0578bc77585bc24bb385cc99862e942e5554dbf3dec02bf081e9'
     Files = @{ 'kanata_windows_tty_winIOv2_x64.exe' = 'bin\kanata.exe'
                'kanata_windows_tty_wintercept_x64.exe' = 'bin\kanata_wintercept.exe' } }
  @{ Url = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/linux-binaries-x64.zip"
     Sha = 'd9f634afb4c7f078cc2aacf3998fd65b432d4d83296cc48a89f941525459b4e2'
     Files = @{ 'kanata_linux_x64' = 'bin\kanata' } }
  @{ Url = 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.19/AutoHotkey_2.0.19.zip'
     Sha = '4e0d0e65655066a646a210951320feaef0729a3597177131adaec4066bef5869'
     Files = @{ 'AutoHotkey64.exe' = 'Hotcray.exe' } }
)
# Windows on ARM: native kanata build (AutoHotkey64.exe runs emulated).
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
  $Downloads[0] = @{
    Url = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/windows-binaries-arm64.zip"
    Sha = 'cbc52b520f62a68cc032df1cfbb93d5793b02612449b9bab573ecd781b253e1f'
    Files = @{ 'kanata_windows_tty_winIOv2_arm64.exe' = 'bin\kanata.exe' } }
}

$Root = $PSScriptRoot
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'bin') | Out-Null
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("hotcray-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
  foreach ($d in $Downloads) {
    $zip = Join-Path $Tmp ([IO.Path]::GetFileName($d.Url))
    Write-Host "Downloading $($d.Url)"
    Invoke-WebRequest -Uri $d.Url -OutFile $zip -UseBasicParsing
    $hash = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLower()
    if ($hash -ne $d.Sha) { throw "Checksum mismatch for $($d.Url)`n  expected $($d.Sha)`n  got      $hash" }
    $out = Join-Path $Tmp ([IO.Path]::GetFileNameWithoutExtension($zip))
    Expand-Archive -Path $zip -DestinationPath $out -Force
    foreach ($name in $d.Files.Keys) {
      $src = Get-ChildItem -Path $out -Recurse -Filter $name | Select-Object -First 1
      if (-not $src) { throw "$name not found in $zip" }
      $dst = Join-Path $Root $d.Files[$name]
      Copy-Item $src.FullName $dst -Force
      Unblock-File $dst      # no "downloaded from the internet" warning on start
      Write-Host "  -> $($d.Files[$name])"
    }
  }
} finally {
  Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
Write-Host "`nDone. Start Hotcray by double-clicking Hotcray.exe."
