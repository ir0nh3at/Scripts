#Fix-ServicePermissions.ps1
#This tool is used to fix permissions on any service with poor protection on its install dir.  Based on my previous work with the Codebook service perms.
#Steve Custer <ir0nh3at@protonmail.com>- 7/8/2019

function Fix-ServicePermissions {

    <#
        .DESCRIPTION
        Sets administrators access to full control and users to Read and Execute.  Used for remediating "Insecure Service Permissions" findings in Nessus.
        .PARAMETER ServicePath
        Local path that needs to be fixed.
        .PARAMETER ComputerName
        Computer name of machine that needs to be fixed.  Defaults to localhost.
    #>
    
    
        param (
            $ComputerName = "localhost",
            [parameter(Mandatory=$true)]
            [string]$ServicePath
            )
    
        $scriptBlock = {
            $servicePath = $using:ServicePath
            $dateForFile = Get-Date -Format "yyyyMMdd_"
            $logPath = "c:\windows\ccm\logs\$dateForFile" + "Script_FixServicePermissions.log"
            Write-Output "$(Get-Date -format "[HH:mm:ss]") Beginning script Fix-ServicePermissions against path $ServicePath" | Tee-Object -FilePath $logPath -append
    
            $servicePresent = Test-Path $ServicePath
    
            if ($servicePresent)
                {
                    Write-Output "$(Get-Date -format "[HH:mm:ss]") Service Path detected at $servicePath." | Tee-Object -FilePath $logPath -append
                    Write-Output "$(Get-Date -format "[HH:mm:ss]") Attempting to fix permissions." | Tee-Object -FilePath $logPath -append
                    $acl = Get-Acl -Path $servicePath
                    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit, ObjectInherit","None","Allow")
                    $UserRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Authenticated Users","ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
                    $acl.SetAccessRuleProtection($True,$False) #Break inheritance, don't copy existing perms.
                    $acl.Access | % {$acl.RemoveAccessRule($_)} #for some reason some of the old ones still stick around sometimes.  This removes them by force.
                    $acl.AddAccessRule($UserRule)
                    $acl.AddAccessRule($adminRule)
                    Set-Acl $servicePath $acl
                    Write-Output "$(Get-Date -format "[HH:mm:ss]") Attempt complete.  Permissions after attempt:" | Tee-Object -FilePath $logPath -append
                    Write-Output $(Get-Acl $servicePath).access
                }
                else
                    {
                        Write-Output "$(Get-Date -format "[HH:mm:ss]") Service not found at $servicePath." | Tee-Object -FilePath $logPath -append
                    }
            } # End ScriptBlock
        Invoke-Command -ScriptBlock $scriptBlock -ComputerName $ComputerName
        }