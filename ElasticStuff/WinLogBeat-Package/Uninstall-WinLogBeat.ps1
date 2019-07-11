#Uninstall-WinLogBeat.ps1
#Uninstalls the relevant WinLogBeat Version.
#Uninstall using powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File c:\Program Files\<version>\Uninstall-WinLogBeat.ps1
#Steve Custer <ir0nh3at@protonmail.com> - 7/10/2019

$targetRoot = "C:\Program Files\"
$directoryName = "winlogbeat-7.2.0-windows-x86_64"
$versionName = "7.2.0"
$targetFull = $targetRoot + $directoryName
$dateForFilename = Get-Date -Format "yyyyMMdd_HHmmss_"
$logPath = "C:\windows\ccm\logs\" + $dateForFilename + $directoryName + "_uninstall.log"
$UninstallRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $directoryName

Write-Output "$(Get-Date -format "[HH:mm:ss]") Uninstalling WinLogBeat $versionName at $targetFull." | Tee-Object -FilePath $logPath -append

#Remove Service (code lifted from provided uninstaller)
# Delete and stop the service if it already exists.
if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
    $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
    $service.StopService()
    Start-Sleep -s 1
    $service.delete()
  }

#Delete Path
Write-Output "$(Get-Date -format "[HH:mm:ss]") Deleting $targetFull" | Tee-Object -FilePath $logPath -append
Remove-Item $targetFull -Recurse -Force

#RemoveUninstallEntry
Write-Output "$(Get-Date -format "[HH:mm:ss]") Removing uninstall entry." | Tee-Object -FilePath $logPath -append
Remove-Item $UninstallRegPath -Recurse -Force
Write-Output "$(Get-Date -format "[HH:mm:ss]") Uninstall Complete." | Tee-Object -FilePath $logPath -append