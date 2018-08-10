function Get-ComputerRsop {
<#
	.SYNOPSIS
		Get-ComputerRsop pulls computer RSOP info using WMI
	.DESCRIPTION
        Get-ComputerRsop pulls computer RSOP info using WMI.  Works better than gpresult over
        a remote session.

        Note that link order 1, Local GPO, is filtered out of the results.

        v1.0 - 8/10/2018 - Steve Custer
	.EXAMPLE
        Get-ComputerRsop
        Returns RSOP data
    .PARAMETER ComputerName
        Name of computer to query.  Default is $env:computername
    .PARAMETER All
        Includes GPOs that aren't applied for some reason.
    .PARAMETER Diag
        Show diagnostic info.
    .NOTES
        If you have a problem, if no one else can help, maybe you can hire, The A-Team.
    #>
param(
        [parameter(Position=0)]
        [string]$ComputerName=$env:COMPUTERNAME,
        [Parameter()]
        [Switch]$All,
        [Switch]$Diag
        
    )

    # Get raw RSOP_GPLink Data
    $objRsop = Get-WmiObject RSOP_GPLink -Namespace root\rsop\computer -ComputerName $ComputerName
    # If you don't want anything, just get the applied stuff.
    if (-not $All)
        {$objRsop = $objRsop | where {$_.appliedOrder} | sort appliedOrder}
    $objRsop = $objRsop | where {$_.GPO -ne 'RSOP_GPO.id="LocalGPO"'} #Filter out local GPO.
    $output =@()
    foreach ($obj in $objRsop)
        {
            Clear-Variable guid -ErrorAction SilentlyContinue
            Clear-variable objGpo -ErrorAction SilentlyContinue
            
            if ($Diag){Write-Host "`n`rProcessing $($obj.GPO)" -ForegroundColor Yellow} #For troubleshooting a failing Get-GPO.
            $guid = $obj.gpo.split('{')[1].split('}')[0] #Text manipulation to get guid.
            if ($Diag){Write-Host "Calculated guid: $guid`n`rAttempting Get-GPO -Guid $guid..." -ForegroundColor Yellow}
            try {$objGpo = Get-GPO -Guid $guid}
            catch {$objGpo = New-Object -TypeName psobject -Property @{DisplayName = "Error retreiving display name."}}
            $output += New-Object -TypeName psobject -Property @{
                DisplayName = $objGpo.DisplayName
                DomainName = $objGpo.DomainName
                Owner = $objGpo.Owner
                Id = $objGpo.Id
                GpoStatus = $objGpo.GpoStatus
                Description = $objGpo.Description
                CreationTime = $objGpo.CreationTime
                ModificationTime = $objGpo.ModificationTime
                UserVersion = $objGpo.UserVersion
                ComputerVersion = $objGpo.ComputerVersion
                WmiFilter = $objGpo.WmiFilter
                ComputerName = $obj.PSComputerName
                AppliedOrder = $obj.appliedOrder
                Enabled = $obj.Enabled
                WmiGuid = $guid
            }
        }

        return $output
}
