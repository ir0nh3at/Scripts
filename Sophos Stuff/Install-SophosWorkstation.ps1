# Install-SophosWorkstation.ps1
# Steve Custer <ir0nh3at@protonmail.com>
# Pre-release 9/11/2018
# Sanitized for public sharing.
# Make sure you adjust the setup options to match your environment!

$timeStart = get-date -Format yyyyMMdd_HHmm
$transcriptPath = "c:\windows\ccm\logs\$timestart" + "_SophosCloudInstall.log"
Start-Transcript $transcriptPath
Write-Output "Beginning Sophos Server install $timeStart"

#Note 3/19/2019: If your computers are named in a way that lines up with your desired groups, you can edit the contents of the
#   $workstationGroups object to have the string to match equal the name of your group.  In our case it made sense to just use
#   one group for all of our workstations, which I called "General Purpose."  Adjust this for your environment.

$workstationGroups = New-Object -TypeName PSObject -Property @{
    #"-l" = "Laptops"
    #"-d" = "Desktops"
    #"-v" = "Virtual"
    "XXXOtherXXX" = "General Purpose"
}

# $groupMatch will never find anything as long as everything is commented out of the $workstationGroups object.
$groupMatch = $workstationGroups | get-member | where {$_.membertype -eq "NoteProperty"} | where {$Env:COMPUTERNAME -match $_.name} | select -first 1
if (-not $groupMatch) {$groupMatch = $workstationGroups | get-member | where {$_.membertype -eq "NoteProperty"} | where {"XXXOtherXXX" -match $_.name}}

$groupName = $workstationGroups.($groupMatch.name)

Write-Output "Using Group Name: $groupName"
$setupOptions = "--devicegroup=`"$groupName`" --products=antivirus,intercept --quiet"

Write-Output "Launching SophosSetup.exe with options: $setupOptions"
Start-Process -FilePath .\SophosSetup.exe -ArgumentList $setupOptions -Wait

Write-Output "Sophos install logs can be found in: $env:TEMP or C:\Windows\Temp."
Write-Output "Thank you for using Happy Fun Script."

Stop-Transcript