# Snippets
# This file is a collection of snippets that don't rate their own files
# Steve Custer - Last Update 8/22/18

return 0 #just in case someone accidentally runs the file.

###
# Pipe results of Get-GPPPassword into Get-GPO to easily find name of vulnerable policies:
$pw = Get-GPPPassword
$pw | where {$_.passwords -ne "[BLANK]"} | % {get-gpo -Guid $_.file.substring(37,36)} | select displayname, gpostatus, id

###
# Update ACL for a bunch of folders, without affecting the root folder itself.
$rootPath = "\\server\share"
$folders = gci $rootPath | where {$_.PSIsContainer}
$ACL_Modify = "Domain\UserOrGroup","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ACL_Modify
$i = 1
$count = $folders.count
foreach ($folder in $folders)
    {
        Write-Host "[$i/$count] " -ForegroundColor Yellow -NoNewline
        Write-Host "Applying ACL to $($folder.fullname)."
        $acl = Get-Acl $folder.FullName
        $acl.AddAccessRule($accessRule)
        $acl | Set-Acl $folder.FullName
    }

###
# Check SCCM for machines that are enabled in AD, but don't have clients.
# Run from SCCM drive
$enabledWS = get-adcomputer -Filter 'Enabled -eq $true' -properties * | where {$_.operatingsystem -like "*Windows 10*" -or $_.operatingsystem -like "*Windows 7*"}
#Filter it down further to machines that have been in contact within 90 days if needed.
$enabledWS = $enabledWS | where {$_.lastLogonDate -gt $(get-date).adddays(-90)}
$output = @()
$enabledWS | % {$objDevice = Get-CMDevice -Name $_.name; if (-not $objDevice.Client){$output += $objDevice}}
$output | % {Add-CMDeviceCollectionDirectMembershipRule -CollectionId COL12345 -ResourceId $_.resourceID}
###

# Check for Windows 10 or Windows 7 machines without Bitlocker keys escrowed in AD.

$output = @()
$enabledWS = get-adcomputer -Filter 'Enabled -eq $true' -properties * | where {$_.operatingsystem -like "*Windows 10*" -or $_.operatingsystem -like "*Windows 7*"}
foreach ($ws in $enabledWS)
    {
        if (-not $(Get-adobject -Filter 'ObjectClass -eq "msFVE-RecoveryInformation"' -SearchBase $ws.DistinguishedName))
            {$output += $ws}
    }

###

