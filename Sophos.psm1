function Reset-SophosHealthService {
#Requires -Version 3.0
<#
    .SYNOPSIS
    Resets the Sophos Health Service on the target computer.
    
    .DESCRIPTION
    Using PS remoting, function will disable tamper protection, stop the health database, rename the health database,
    restart the service, and re-enable tamper protection.  It is critical that you trigger a password reset or document
    the password in case something goes awry in the future.

    Written by Steve Custer <ir0nh3at@protonmail.com>
    Last change: 11/28/2018

    .PARAMETER ComputerName
    The target computer.  Defaults to localhost.

    .PARAMETER TamperProtectionPassword
    This is the password found by opening the device in Sophos Central and viewing the Current Password.  If tamper protection
    is currently disabled, you can leave blank.  However, the function will *always* turn tamper protection back on.
#>

param(
    [string]$ComputerName="localhost",
    [Parameter(Mandatory=$true)]
    [string]$TamperProtectionPassword
)

$testConnection = Test-Connection $computername -Count 1

#These are the return codes from SEDcli.
$msgDisabled = "SED Tamper Protection is disabled"
$msgNotOn = "SED Tamper Protection is not currently on"
$msgIncorrectPassword = "Incorrect SED Tamper Protection password provided"
$msgNewPassword = "SED Tamper Protection is enabled. New password:"

if ($testConnection)
    {
        $scriptBlockResetHealth = {
        Write-Output "Running Sophos Health Cleanup on $env:COMPUTERNAME."
        try {gci "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe" -ErrorAction Stop | Out-Null} #Check for SEDcli.exe, error out if missing.
        catch {
            Write-Error "C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe not found!"
            Exit
            }
        Write-Output "Using Tamper Protection Password: $using:TamperProtectionPassword"
        $result = & 'C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe' -TPoff $using:TamperProtectionPassword
        if ($result -ne $using:msgDisabled -and $result -ne $using:msgNotOn)
            {
                Write-Error "Failed to disable tamper protection.  Message from SEDCli: $result"
                Exit
            }
        $i = 1 #counter for stop attempts.
        $maxStopAttempts = 10
        $StopSuccess = $null
        while ($i -le $maxStopAttempts -and !$StopSuccess)
            {
                Write-Output "[Attempt $i/$maxStopAttempts]: Attempting to stop Sophos Health Service."
                try 
                    {
                        Stop-Service "sophos health service" -ErrorAction Stop
                        if ($(Get-Service "sophos health service").Status -ne "Running")
                            {$StopSuccess = $true}
                    }
                catch
                    {
                        Write-Output "[Attempt $i/$maxStopAttempts]: Failed to stop Sophos Health Service."
                        $i++
                        $seconds = 10 + 2 * $i
                        if ($i -lt 10){Start-Sleep -Seconds $seconds}
                    }
            }
            if ($i -ge $maxStopAttempts)
                {
                    Write-Error "Could not stop Sophos Help Service!"
                    Exit
                }
                Write-Output "Sophos Health Service stopped successfully."
                Start-Sleep -Seconds 10
                Rename-Item 'C:\programdata\Sophos\Health\Event Store\Database\events.db' "$(get-date -format yyyyMMdd_HHmmss)_events.db.bad"
                Write-Output "Restarting Sophos Health Service."
                Start-Service "Sophos Health Service"
                $result = & 'C:\Program Files\Sophos\Endpoint Defense\SEDcli.exe' -TPon
                $newPassword = $result.split(':')[1].substring(1)
                Write-Output "Tamper Protection password changed to $newPassword.  Document this in your ticket, or go to Sophos Central, find the machine, and click `"Generate New Password`"."
            }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlockResetHealth   
    }
else {Write-Error "$computerName is not online!"}

}