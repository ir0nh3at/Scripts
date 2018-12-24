#Sophos Central Uninstall SCCM Application Detection Script
#Steve Custer <ir0nh3at@protonmail.com> - 12/21/18

#Use as detection method in SCCM for uninstall.
#Makes sure uninstall was successful.
#You can't use this reliably with the install detection method I previously created.  That's why the uninstall is a 
#separate application.

#paths to check:
$avPathsToCheck = "C:\Program Files (x86)\Sophos\Sophos Anti-Virus\savservice.exe",
                  "C:\Program Files (x86)\Sophos\Sophos Anti-Virus\savAdminService.exe"
$auPathsToCheck = "C:\Program Files (x86)\Sophos\AutoUpdate\SophosUpdate.exe"
$mcsPathsToCheck = "C:\Program Files (x86)\Sophos\Management Communications System\Endpoint\McsAgent.exe",
                   "C:\Program Files (x86)\Sophos\Management Communications System\Endpoint\McsClient.exe"
$cleanPathsToCheck = "C:\Program Files (x86)\Sophos\Clean\Clean.exe"
$healthPathsToCheck = "C:\Program Files (x86)\Sophos\Health\Health.exe",
                      "C:\Program Files (x86)\Sophos\Health\HealthClient.exe"

#Services to check:
#We're just going to check for existence and trust that any that aren't running yet will get picked up by the Sophos console.
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


$pathsToCheck = $avPathsToCheck + $auPathsToCheck + $mcsPathsToCheck
$pathFound = @()
foreach ($path in $pathsToCheck)
    {
        try {$pathFound += gci $path -erroraction Stop}
            catch {continue}
    }
if ($pathFound){$pathFound = $true} #if there's anything in $pathFound, set it to a boolean true.

$servicesPresent = $servicesToCheck | % {Get-Service $_ -ErrorAction SilentlyContinue}
$serviceFound = $servicesPresent.count -gt 0 #if there are any services remaining, this goes to $true
$productFound = get-wmiobject win32_product | where {$_.vendor -like "*sophos*"}

#This is gong to be set backwards due to the way we're using the detection method.
#In this case, "Installed" really means that Sophos uninstalled successfully (services and paths all empty).
if (!$serviceFound -and !$pathFound -and !$productFound)
    {Write-Host "installed"}else {
    }
