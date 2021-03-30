#Install-NGT.ps1
#Installs Nutanix Guest Tools.  Really shouldn't be necessary to script this, but their installer is buggy.  In future versions, test to see if this is still needed.
#Install using powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File .\Install-NGT.ps1
#6/5/2020 - Installer is still glitchy - Continuing with this method - SC

$cacheLocation = Get-Location #get current location, ie c:\windows\ccmcache\whatever
$installPath = $cacheLocation.Path + "\installer\windows"
Set-Location $installPath
start-process .\Nutanix-NGT-20190426.exe -ArgumentList "/quiet /norestart ACCEPTEULA=yes -log c:\windows\ccm\logs" -Wait