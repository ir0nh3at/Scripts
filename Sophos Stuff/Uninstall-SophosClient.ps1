#Uninstall-SophosEndpoint
#Steve Custer <ir0nh3at@protonmail.com> - 12/21/2018

#Return Codes:
#-1: Last line in log not like "*Uninstallation completed successfully*".
#-2: Tamper Protection is Enabled.
#-3: Missing uninstallcli.exe.
#-4: Services still present.
#-5: Executables still present.
#-6: Something detected in win32_product.

$dateForFile = Get-date -Format "yyyyMMdd_HHmmss_"
$transcriptPath = "c:\windows\ccm\logs\$dateForFile" + "SophosEndpointUninstallTranscript.log"
$uninstallCliOutput = "c:\windows\ccm\logs\$dateForFile" + "SophoEndpointUninstall_uninstallCliOutput.log"
$uninstallerPath = 'C:\Program Files\Sophos\Sophos Endpoint Agent\uninstallcli.exe'

#These are the return codes from SEDcli.
$msgDisabled = "SED Tamper Protection is disabled"
$msgNotOn = "SED Tamper Protection is not currently on"
$msgIncorrectPassword = "Incorrect SED Tamper Protection password provided"
$msgNewPassword = "SED Tamper Protection is enabled. New password:"

#paths to check:
$PathsToCheck = "C:\Program Files (x86)\Sophos\Sophos Anti-Virus\savservice.exe",
                "C:\Program Files (x86)\Sophos\Sophos Anti-Virus\savAdminService.exe"
                "C:\Program Files (x86)\Sophos\AutoUpdate\SophosUpdate.exe",
                "C:\Program Files (x86)\Sophos\Management Communications System\Endpoint\McsAgent.exe",
                "C:\Program Files (x86)\Sophos\Management Communications System\Endpoint\McsClient.exe",
                "C:\Program Files (x86)\Sophos\Clean\Clean.exe",
                "C:\Program Files (x86)\Sophos\Health\Health.exe",
                "C:\Program Files (x86)\Sophos\Health\HealthClient.exe"

#Services to check:
$servicesToCheck =  "Sophos AutoUpdate Service",
                    "Sophos Clean Service",
                    "Sophos Device Control Service",
                    "Sophos Endpoint Defense Service",
                    "Sophos File Scanner Service",
                    "Sophos Health Service",
                    "Sophos MCS Agent",
                    "Sophos MCS Client",
                    "Sophos Safestore Service",
                    "Sophos System Protection Service",
                    "Sophos Web Control Service",
                    "HitmanPro.Alert Service",
                    "Sophos Network Threat Prevention"

Start-Transcript -Path $transcriptPath

Write-Output "Beginning Sophos Endpoint Uninstall Script"
Write-Output "---=== Variables ===---"
Write-Output "dateForFile: $dateForFile"
Write-Output "transcriptPath: $transcriptPath"
Write-Output "uninstallCliOutput: $uninstallCliOutput"
Write-Output "`n"

Write-Output "Checking for existence of $uninstallerPath..."

try {gci $uninstallerPath -ErrorAction Stop | Out-Null} #Check for uninstaller, error out if missing.
    catch {
        Write-Output "ERROR: $uninstallerPath not found!"
        Write-Output "Returning error code -3."
        Stop-Transcript
        return -3
        }

Write-Output "$uninstallerPath found!`n"
Write-Output "Verifying Tamper Protection is off..."

$result = & 'C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe' -status
if ($result -ne $msgDisabled)
    {
        Write-Output "ERROR: Tamper Protection not off!"
        Write-Output "Status from SEDcli: $result"
        Write-Output "Returning error code -2"
        return -2
    }

Write-Output "Tamper protection appears to be off."
Write-Output "Status from SEDcli: $result"

Write-Output "All systems go.  Attempting uninstall. https://www.youtube.com/watch?v=PhLgUv6sTFI"

Write-Output "Running uninstaller."
Start-Process -FilePath $uninstallerPath -wait -RedirectStandardOutput $uninstallCliOutput

Write-Output "`nUninstaller complete."
Write-Output "Validating Uninstall..."
Write-Output "Checking uninstaller log result..."
if ($(get-content $uninstallCliOutput | select -Last 1) -notlike "*Uninstallation completed successfully*")
    {
        Write-Output "ERROR: Uninstaller doesn't appear to have completed successfully."
        Write-Output "Returning -1"
        Stop-Transcript
        return -1
    }

Write-Output "Uninstaller log looks good..."
Write-Output "Checking services..."

$servicesPresent = $servicesToCheck | % {Get-Service $_ -ErrorAction SilentlyContinue}
if ($servicesPresent)
    {
        Write-Output "ERROR: Some Sophos services remain!"
        Write-Output "Contents of servicesPresent: `n$servicesPresent"
        Write-Output "Returning -4"
        Stop-Transcript
        return -4
    }

Write-Output "No services remain."
Write-Output "Checking for remaining files..."

$pathFound = @()
foreach ($path in $pathsToCheck)
    {
        try {$pathFound += gci $path -erroraction Stop}
            catch {continue}
    }

if ($pathFound)
    {
        Write-Output "ERROR: Some Sophos files remain!"
        Write-Output "Files found: `n$($pathFound.fullname)"
        Write-Output "`nReturning -5"
        Stop-Transcript
        return -5
    }

Write-Output "No files on checklist remain."
Write-Output "Checking win32_product..."
$sophosProduct = get-wmiobject win32_product | where {$_.vendor -like "*sophos*"}
if ($sophosProduct)
    {
        Write-Output "ERROR: Some Sophos products still detected in win32_product!"
        Write-Output "Products found: `n$sophosProduct"
        Write-Output "`nReturning -6"
        Stop-Transcript
        return -6
    }

Write-Output "No products detected in win32_product."
Write-Output "All checks complete.  Returning 0."

Stop-Transcript
return 0
