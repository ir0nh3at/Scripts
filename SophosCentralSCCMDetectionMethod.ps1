#Sophos Central SCCM Application Detection Script
#Steve Custer <ir0nh3at@protonmail.com> - 11/29/18

#Use as detection method in SCCM.
#Using just the product code is annoying because Sophos changes it all the time, making the app break in SCCM periodically.

#Not currently detecting on Build/priv numbers, but stuck them in here for potential future use.
#Sophos Anti-Virus: Minimum version to detect: 10.8.x.x
$avMinProdMajor = 10
$avMinProdMinor = 8
#$avMinProdBuild = 2
#$avMinProdPriv = 0

#Sophos AutoUpdate: Minimum version to detect: 5.13.x.x
$auMinProdMajor = 5
$auMinProdMinor = 13
#$auMinProdBuild = 0
#$auMinProdPriv = 0

#Sophos Management Communications System: Minimum version to detect: 4.9.x.x
$mcsMinProdMajor = 4
$mcsMinProdMinor = 9
#$mcsMinProdBuild = 0
#$mcsMinProdPriv = 0

#Sophos Clean: Minimum version to detect: 3.0.0.0
$cleanMinProdMajor = 3
$cleanMinProdMinor = 0
#$cleanMinProdBuild = 0
#$cleanMinProdPriv = 0

#Sophos Health: Minimum version to detect: 2.0.7.0
$healthMinProdMajor = 2
$healthMinProdMinor = 0
#$healthMinProdBuild = 0
#$healthMinProdPriv = 0



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
                    "Sophos Web Control Service"

function Check-FileVersionGreater {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$FilePaths,
        [int]$MinProdMajor,
        [int]$MinProdMinor
    )
    
    foreach ($file in $filePaths)
        {
            $fileVersion = $(gci $file).VersionInfo
            if ($fileVersion.ProductMajorPart -lt $MinProdMajor){return $false}
                elseif ($fileVersion.ProductMinorPart -lt $MinProdMinor){return $false}
        }
    return $true
    }

#Prepwork is done, time to party!
$avSuccess = Check-FileVersionGreater -FilePaths $avPathsToCheck -MinProdMajor $avMinProdMajor -MinProdMinor $avMinProdMinor
$auSuccess = Check-FileVersionGreater -FilePaths $auPathsToCheck -MinProdMajor $auMinProdMajor -MinProdMinor $auMinProdMinor
$mcsSuccess = Check-FileVersionGreater -FilePaths $mcsPathsToCheck -MinProdMajor $mcsMinProdMajor -MinProdMinor $mcsMinProdMinor
$cleanSuccess = Check-FileVersionGreater -FilePaths $cleanPathsToCheck -MinProdMajor $cleanMinProdMajor -MinProdMinor $cleanMinProdMinor
$healthSuccess = Check-FileVersionGreater -FilePaths $healthPathsToCheck -MinProdMajor $healthMinProdMajor -MinProdMinor $healthMinProdMinor

#Kind of weird way to do the service check, but it should work.
$servicesPresent = $servicesToCheck | % {Get-Service $_}
$serviceSuccess = $servicesPresent.count -eq $servicesToCheck.Count

if ($avSuccess -and $auSuccess -and $mcsSuccess -and $cleanSuccess -and $healthSuccess -and $serviceSuccess)
    {Write-Host "installed"}else {
    }
