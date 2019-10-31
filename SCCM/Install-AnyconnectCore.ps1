#Install-AnyConnectCore.ps1
#Installs AnyConnect Core.  Wouldn't need this, except for some reason the management profile doesn't automatically copy over.
#Install using: powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File .\Install-AnyConnectCore.ps1
#SC 3/19/2019
#3/25/2019 - Added check to see if currently on VPN, erroring out with code 999 if currently on VPN. - SC
#3/28/2019 - Commenting out the check for currently being on the VPN.  The DA exclusions have been fixed. - SC
#3/28/2019 - Need to delete preferences.xml to clear old cached VPN server.  Loop added at end of script. - SC

$dateForFile = Get-Date -Format "yyyyMMdd_HHmmss_" #puts date in a format we can use for prepending file names.
$logPath = "C:\windows\ccm\logs\"
$scriptLog = $logPath + $dateForFile + "AnyConnectInstallScriptLog.log" #output from this script will be here.
$msiLogPath = $logPath + $dateForFile + "AnyConnectInstallMSILog.log" #output from msiexec will be here.
$mgmtTunSource = ".\Profiles\VPN\MgmtTun\<source profile location>.vpnm"
$mgmtTunDest = "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\MgmtTun\<New Management Profile Location>.vpnm"
$oldProfilesToRemove = "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\<OldProfile1>.xml",
                       "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\<OldProfile2>.xml",
                       "C:\ProgramData\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\<OldProfile3>.xml"

Write-Output "$(Get-Date -format "[HH:mm:ss]") Beginning AnyConnect Install Script." | Tee-Object -FilePath $scriptLog -append

Write-Output "$(Get-Date -format "[HH:mm:ss]") Looking for AnyConnect Core MSI..." | Tee-Object -FilePath $scriptLog -append

#We're going to find the anyconnect MSI in this folder.  I'm not specifying it so that we can use the same script with multiple versions without updating.

$msiPath = (gci "anyconnect*core*vpn*.msi").Name 
if ($msiPath.count -ne 1) #If there's more than one matching file in the directory or none, error out.
    {
        Write-Output "$(Get-Date -format "[HH:mm:ss]") Error detecting MSI path.  Either too many files match or zero files match." | Tee-Object -FilePath $scriptLog -append
        return -1
    }
    else 
        {
            Write-Output "$(Get-Date -format "[HH:mm:ss]") Detected MSI at $msiPath." | Tee-Object -FilePath $scriptLog -append
        }

Write-Output "$(Get-Date -format "[HH:mm:ss]") Kicking off MSI install." | Tee-Object -FilePath $scriptLog -append
Start-Process msiexec -ArgumentList "/i $msiPath /qn /norestart /L*v $msiLogPath" -Wait >> $scriptLog
Write-Output "$(Get-Date -format "[HH:mm:ss]") MSI install complete." | Tee-Object -FilePath $scriptLog -append #I'm not worried about detecting success here.  If it fails, SCCM will catch it.
Write-Output "$(Get-Date -format "[HH:mm:ss]") Copying MgmtTun profile to $mgmtTunDest" | Tee-Object -FilePath $scriptLog -append
Copy-Item $mgmtTunSource -Destination $mgmtTunDest -Force >> $scriptLog
if (-not (Test-Path $mgmtTunDest))
        {
            Write-Output "$(Get-Date -format "[HH:mm:ss]") ERROR: $mgmtTunDest not found after copy attempt." | Tee-Object -FilePath $scriptLog -append
            return -2
        }

foreach ($oldProfileToRemove in $oldProfilesToRemove)
        {
            If (test-path $oldProfileToRemove)
                {
                    Write-Output "$(Get-Date -format "[HH:mm:ss]") WARNING: Old profile $oldProfileToRemove detected!" | Tee-Object -FilePath $scriptLog -append
                    Remove-Item $oldProfileToRemove -Force
                    If (Test-Path $oldProfileToRemove){Write-Output "$(Get-Date -format "[HH:mm:ss]") ERROR: $oldProfileToRemove still present!  This is a non-terminating error." | Tee-Object -FilePath $scriptLog -append}
                        else
                            {
                                Write-Output "$(Get-Date -format "[HH:mm:ss]") $oldProfileToRemove removed successfully." | Tee-Object -FilePath $scriptLog -append
                            }
                }
        }

#Need to remove preferences.xml to really clear out the old profiles.
$userDirs = gci c:\users | where {$_.name -notlike "public" -and $_.name -notlike "default*"}
foreach ($dir in $userDirs)
        {
            if (Test-path "$($dir.fullname)\appdata\local\Cisco\Cisco AnyConnect Secure Mobility Client\preferences.xml")
                {Remove-Item "$($dir.fullname)\appdata\local\Cisco\Cisco AnyConnect Secure Mobility Client\preferences.xml"}
        }

Write-Output "$(Get-Date -format "[HH:mm:ss]") Install-AnyConnectCore.ps1 is complete." | Tee-Object -FilePath $scriptLog -append
Write-Output "$(Get-Date -format "[HH:mm:ss]") MSI log can be found at $msiLogPath. " | Tee-Object -FilePath $scriptLog -append
Write-Output "$(Get-Date -format "[HH:mm:ss]") Have a super day." | Tee-Object -FilePath $scriptLog -append
Write-Output "$(Get-Date -format "[HH:mm:ss]") PS: If you're feeling down, watch https://www.youtube.com/watch?v=iK6SS8CXYZo." | Tee-Object -FilePath $scriptLog -append
