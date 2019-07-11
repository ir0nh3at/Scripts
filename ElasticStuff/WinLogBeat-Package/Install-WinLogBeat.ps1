#Install-WinLogBeat.ps1
#Install using powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File .\Install-WinLogBeat.ps1 -Site LON
#Steve Custer <ir0nh3at@nbbj.com> - 7/10/2019

param(
    [string]$site = "Default"
)

$targetRoot = "C:\Program Files\"
$directoryName = "winlogbeat-7.2.0-windows-x86_64"
$versionName = "7.2.0"
$targetFull = $targetRoot + $directoryName
$dateForFilename = Get-Date -Format "yyyyMMdd_HHmmss_"
$logPath = "C:\windows\ccm\logs\" + $dateForFilename + $directoryName + "_install.log"
$UninstallRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $directoryName

Write-Output "$(Get-Date -format "[HH:mm:ss]") Installing Winlogbeat $versionName to $targetFull with config for site $site." | Tee-Object -FilePath $logPath -append
Write-Output "$(Get-Date -format "[HH:mm:ss]") Running from $(get-location)." | Tee-Object -FilePath $logPath -append

#Check for root path, create if necessary.
Write-Output "$(Get-Date -format "[HH:mm:ss]") Creating $targetRoot if necessary." | Tee-Object -FilePath $logPath -append
try {Test-Path $targetRoot}
    catch {mkdir -Path $targetRoot | Out-Null}

#Copy the directory.
Write-Output "$(Get-Date -format "[HH:mm:ss]") Copying $directoryName to $targetFull." | Tee-Object -FilePath $logPath -append
Copy-Item .\$directoryName $targetFull -Recurse

#Installing Service (code lifted and tweaked from provided install-winlogbeat-service.ps1)
#Note the change in the path to the config file when creating the service; this is where the site parameter comes in.
# Delete and stop the service if it already exists.
if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
    $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
    $service.StopService()
    Start-Sleep -s 1
    $service.delete()
  }
  
  $workdir = $targetFull #just did this so I didn't have to change the lifted code more than necessary.
  
  # Create the new service.
  New-Service -name winlogbeat `
    -displayName Winlogbeat `
    -binaryPathName "`"$workdir\winlogbeat.exe`" -c `"$workdir\configs\$site.yml`" -path.home `"$workdir`" -path.data `"C:\ProgramData\winlogbeat`" -path.logs `"C:\ProgramData\winlogbeat\logs`""
  
  # Attempt to set the service to delayed start using sc config.
  Try {
    Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start=delayed-auto'
  }
  Catch { Write-Host "An error occured setting the service to delayed start." -ForegroundColor Red }

#Create Uninstall Registry Entries
Write-Output "$(Get-Date -format "[HH:mm:ss]") Setting Uninstall Registry Settings." | Tee-Object -FilePath $logPath -append
if (!(Test-Path $UninstallRegPath)) #Check for Path, create if necessary
    {New-Item -Path $UninstallRegPath -ItemType Container | Out-Null}

$DisplayIcon = $targetFull + "\WinLogBeat.ico"
$UninstallScript = $targetFull + "\Uninstall-WinLogBeat.ps1"
$UninstallString = "powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File `"$UninstallScript`""

New-ItemProperty -Path $UninstallRegPath -Name "DisplayIcon" -Value $DisplayIcon -PropertyType String -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "DisplayName" -Value "WinLogBeat $versionName" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "DisplayVersion" -Value "$versionName" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "InstallLocation" -Value $targetFull -PropertyType String -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "NoModify" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "NoRepair" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "Publisher" -Value "Elastic.co (Packaged by ir0nh3at)" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "VersionMajor" -Value $versionName.split('.')[0] -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "VersionMajor" -Value $versionName.split('.')[1] -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $UninstallRegPath -Name "UninstallString" -Value $UninstallString -PropertyType String -Force | Out-Null

#Start Service
Start-Service winlogbeat

Write-Output "$(Get-Date -format "[HH:mm:ss]") Installation Complete." | Tee-Object -FilePath $logPath -append