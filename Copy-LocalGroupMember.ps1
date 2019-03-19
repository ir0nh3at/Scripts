#Copy-LocalGroupMember.ps1
 <#
        .DESCRIPTION
        Copies group members from one local group to another.  Original use case: copying members from local administrators to remote desktop
        users in preparation for removing local admin rights from domain users.
        .PARAMETER CopyFromGroup
        Group name to copy from.  For example, "Administrators"
        .PARAMETER CopyToGroup
        Group to copy to.  Group must already exist.
        .PARAMETER ComputerName
        Computer to execute on.  Defaults to local computer.
        .PARAMETER SkipEntities
        Array of strings containing users and groups to skip in the copy.  For example, "DOMAIN\Domain Admins","$env:COMPUTERNAME\Administrators","DOMAIN\HelpDesk"
        .EXAMPLE
        .EXAMPLE
        .NOTES
        Some code taken from https://stackoverflow.com/questions/32665284/get-the-domain-name-of-the-user-of-adsi-object
        Some code taken from https://mcpmag.com/articles/2015/06/18/reporting-on-local-groups.aspx
        Steve Custer <ir0nh3at@protonmail.com> - 3/1/2019
    #>

param(
    $ComputerName = $ENV:COMPUTERNAME,
    [String[]]$SkipEntities,
    [Parameter(Mandatory=$true)]
    [String]$CopyFromGroup,
    [String]$CopyToGroup
)

$objSourceGroup = [ADSI]"WinNT://$computerName/$CopyFromGroup,group" #Creates object for source group.
$objDestinationGroup = [ADSI]"WinNT://$computerName/$CopyToGroup,group" #Creates object for source group.

#Loop through objects in source group.  Check if they're on the skip list, if not, add to array.
$copySid = @()
$objSourceGroup.psbase.Invoke("Members") | ForEach-Object {
    $bytes = $_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null)
    $Sid = New-Object Security.Principal.SecurityIdentifier ($bytes, 0)
    if ($sid.Translate([Security.Principal.NTAccount]) -notin $SkipEntities)
        {$copySid += $sid}
    }

#Now that we have a list of SIDs to add to the other group, let's do that.
foreach ($objSid in $copySid)
    {
        $objEntity = [ADSI]"WinNT://$($objSid.value)"
        $objDestinationGroup.Add($objEntity.AdsPath)
    }


