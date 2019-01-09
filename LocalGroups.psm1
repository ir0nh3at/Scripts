function Add-ADObjectToLocalGroup {
    <#
        .DESCRIPTION
        Adds an AD object to a computer's local group.  Requires AD module.
        .SYNOPSIS
        Adds an AD object to a computer's local group.  Requires AD module.
        .PARAMETER ComputerName
        The name of the computer whose local group is being changed.  Defaults to the current computer.
        .PARAMETER LocalGroupName
        Mandatory.  Typically will be Administrators or "Remote Desktop Users"
        .PARAMETER ObjectSamAccountName
        Mandatory.  The SamAccountName of the object.  If you're adding a computer object, make sure you use the $ (for example: "ComputerName$")
        .EXAMPLE
        > Add-ADObjectToLocalGroup -ComputerName Computer01 -ObjectSamAccountName juser -LocalGroupName "Remote Desktop Users"
        Adds user juser to the "Remote Desktop Users" local group on Computer01.
        .EXAMPLE
        > Add-ADObjectToLocalGroup -ComputerName Computer01 -ObjectSamAccountName HelpDesk -LocalGroupName Administrators
        Adds the AD group HelpDesk to the "Administrators" local group on Computer01.
        .EXAMPLE
        > Add-ADObjectToLocalGroup -ComputerName Computer01 -ObjectSamAccountName Server01$ -LocalGroupName "Remote Desktop Users"
        Adds the computer Server01 to the "Remote Desktop Users" local group on Computer01.
        .NOTES
        Steve Custer <ir0nh3at@protonmail.com>
        I lifted some of the code from somewhere, but I don't recall where.  It's pretty standard stuff, though.  The remoting and
        prettying things up was me, though.
        Yes, PS 5.1 contains official cmdlets for this, but if you're not up to PS 5.1, then here you go...
    #>

    param(
        [String]$ComputerName=$env:COMPUTERNAME,
        [Parameter(Mandatory=$true)]
        [String]$LocalGroupName,
        [String]$ObjectSamAccountName
    )

    $ObjectSid = $(get-adobject -Filter 'samaccountname -like $ObjectSamAccountName' -Properties objectsid).objectsid.value
    
    $debugInfo = "`nComputerName: $ComputerName
    LocalGroupName: $LocalGroupName
    ObjectSamAccountName: $ObjectSamAccountName
    ObjectSid: $ObjectSid"
    Write-Debug -Message $debugInfo

    $scriptBlock = {
                    $localGroup = $using:LocalGroupName
                    $domainSID = $using:ObjectSid
                    
                    $objLocalGroup = [ADSI]"WinNT://localhost/$localgroup,group" #Creates object for local group.
                    $objADObject = [ADSI]"WinNT://$domainSid" #Creates object for the AD Object
                    
                    $objLocalGroup.Add($objADObject.AdsPath) #Adds the Group.  Will generate error if already there.
                    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock 
}


function Remove-ADObjectFromLocalGroup {
    <#
        .DESCRIPTION
        Removes an AD object from a computer's local group.  Requires AD module.
        .SYNOPSIS
        Removes an AD object from a computer's local group.  Requires AD module.
        .PARAMETER ComputerName
        The name of the computer whose local group is being changed.  Defaults to the current computer.
        .PARAMETER LocalGroupName
        Mandatory.  Typically will be Administrators or "Remote Desktop Users"
        .PARAMETER ObjectSamAccountName
        Mandatory.  The SamAccountName of the object.  If you're removing a computer object, make sure you use the $ (for example: "ComputerName$")
        .EXAMPLE
        > Remove-ADObjectFromLocalGroup -ComputerName Computer01 -ObjectSamAccountName juser -LocalGroupName "Remote Desktop Users"
        Removes user juser to the "Remote Desktop Users" local group on Computer01.
        .EXAMPLE
        > Remove-ADObjectFromLocalGroup -ComputerName Computer01 -ObjectSamAccountName HelpDesk -LocalGroupName Administrators
        Removes the AD group HelpDesk to the "Administrators" local group on Computer01.
        .EXAMPLE
        > Remove-ADObjectFromLocalGroup -ComputerName Computer01 -ObjectSamAccountName Server01$ -LocalGroupName "Remote Desktop Users"
        Removes the computer Server01 to the "Remote Desktop Users" local group on Computer01.
        .NOTES
        Steve Custer <ir0nh3at@protonmail.com>
        I lifted some of the code from somewhere, but I don't recall where.  It's pretty standard stuff, though.  The remoting and
        prettying things up was me, though.
        Yes, PS 5.1 contains official cmdlets for this, but if you're not up to PS 5.1, then here you go...
    #>

    param(
        [String]$ComputerName=$env:COMPUTERNAME,
        [Parameter(Mandatory=$true)]
        [String]$LocalGroupName,
        [String]$ObjectSamAccountName
    )

    $ObjectSid = $(get-adobject -Filter 'samaccountname -like $ObjectSamAccountName' -Properties objectsid).objectsid.value
    
    $debugInfo = "`nComputerName: $ComputerName
    LocalGroupName: $LocalGroupName
    ObjectSamAccountName: $ObjectSamAccountName
    ObjectSid: $ObjectSid"
    Write-Debug -Message $debugInfo

    $scriptBlock = {
                    $localGroup = $using:LocalGroupName
                    $domainSID = $using:ObjectSid
                    
                    $objLocalGroup = [ADSI]"WinNT://localhost/$localgroup,group" #Creates object for local group.
                    $objADObject = [ADSI]"WinNT://$domainSid" #Creates object for the AD Object
                    
                    $objLocalGroup.Remove($objADObject.AdsPath) #Removes the Group.  Will generate error if already there.
                    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock 
}
