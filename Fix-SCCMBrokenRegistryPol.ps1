function Fix-SCCMBrokenRegistryPol {
    <#
        .SYNOPSIS
            Quick and dirty - checks UpdatesHandler.log for an access denied error, then deletes
            c:\Windows\system32\GroupPolicy\Machine\Registry.pol amd triggers a few of SCCM's tasks.
        .NOTES
            9/13/2018 - Steve Custer
    #>

    param (
        [parameter(Position=0)]
            [string]$ComputerName=$env:COMPUTERNAME
        )

    $UpdatesHandlerLogPath = "\\$computername\c$\windows\ccm\logs\updateshandler.log"
    if (get-content $UpdatesHandlerLogPath | select -Last 8 | where {$_ -like "*0x80004005*"})
        {
            Write-Host "Error found in $updatesHandlerLogPath!  Proceeding with cleanup." -ForegroundColor Yellow
            del \\$ComputerName\c$\Windows\system32\GroupPolicy\Machine\Registry.pol
            $triggers = "{00000000-0000-0000-0000-000000000001}",
                        "{00000000-0000-0000-0000-000000000002}",
                        "{00000000-0000-0000-0000-000000000003}",
                        "{00000000-0000-0000-0000-000000000108}",
                        "{00000000-0000-0000-0000-000000000113}"

            $triggers | % {Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $_ -ComputerName $ComputerName}
        }
        else {Write-Host "$updatesHandlerLogPath not found or no error!" -ForegroundColor yellow}
    }

    Fix-SCCMBrokenRegistryPol $args[0]