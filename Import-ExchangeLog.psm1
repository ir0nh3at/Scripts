function Import-ExchangeLog {
<#
    .DESCRIPTION
    Imports and objectifies an exchange log, such as the httpproxy, ews, or owa logs.  Assumes fields are listed on first line.
    .SYNOPSIS
    Imports and objectifies an exchange log, such as the http, ews, or owa logs.
    .PARAMETER FileNames
    String array containing the path to the files you want to import.
    .PARAMETER SkipCount
    Number of lines from the top of the file to the first entry.  In my experience it's typically around six for Exchange.
    .EXAMPLE
    # Parse the three newest logs for items logged by DOMAIN\SuspiciousUser:
    > $files = (gci c:\temp\logs | sort LastWriteTime -descending | select -first 3).fullname #Select the three most recent logs in the directory.
    > $importedLogs = Import-ExchangeLog -FileNames $files -SkipCount 6 #Import the logs to $importedLogs
    [1/3] Importing c:\temp\logs\HttpProxy_2018121416-1.LOG.
    [2/3] Importing c:\temp\logs\HttpProxy_2018121415-2.LOG.
    [3/3] Importing c:\temp\logs\HttpProxy_2018121415-1.LOG.
    > $importedLogs | where {$_.AuthenticatedUser -eq DOMAIN\SuspiciousUser} | out-gridview #open a grid view with all entries where SuspiciousUser is the Authenticated user.
    .EXAMPLE
    # Find information about the imported log object.
    > $importedLog = Import-ExchangeLog -FileNames .\HttpProxy_2018121416-1 -SkipCount 6 #Import the log to $importedLog.
    > $importedLog | Get-Member
    > $importedLogs | get-member

        TypeName: System.Management.Automation.PSCustomObject

        Name                            MemberType   Definition
        ----                            ----------   ----------
        Equals                          Method       bool Equals(System.Object obj)
        GetHashCode                     Method       int GetHashCode()
        GetType                         Method       type GetType()
        ToString                        Method       string ToString()
        AccountForestLatencyBreakup     NoteProperty string AccountForestLatencyBreakup=
        ActivityContextLifeTime         NoteProperty string ActivityContextLifeTime=505424
        ADLatency                       NoteProperty string ADLatency=0
        AnchorMailbox                   NoteProperty string AnchorMailbox=Sid~S-1-5-21-88888888888-8888888888-888888888-8888
        AuthenticatedUser               NoteProperty string AuthenticatedUser=DOMAIN\SuspiciousUser
        AuthenticationType              NoteProperty string AuthenticationType=Basic
        AuthModulePerfContext           NoteProperty string AuthModulePerfContext=
        BackEndCookie                   NoteProperty string BackEndCookie=Database~162703ce-4a47-406d-a552-5d1e3d524d08~~201...
        BackEndGenericInfo              NoteProperty string BackEndGenericInfo=
        BackendProcessingLatency        NoteProperty string BackendProcessingLatency=505418
        BackendReqInitLatency           NoteProperty string BackendReqInitLatency=
        BackendReqStreamLatency         NoteProperty string BackendReqStreamLatency=
        BackendRespInitLatency          NoteProperty string BackendRespInitLatency=1
        BackendRespStreamLatency        NoteProperty string BackendRespStreamLatency=0
        BackEndStatus                   NoteProperty string BackEndStatus=200
        BuildVersion                    NoteProperty string BuildVersion=1367
        CalculateTargetBackEndLatency   NoteProperty string CalculateTargetBackEndLatency=0
        ...
    .NOTES
    Steve Custer <ir0nheat@protonmail.com> Last change 12/24/2018
#>

    param (
        [int32]$SkipCount=0,
        [Parameter(Mandatory=$true)]
        [string[]]$FileNames
        )

$output = @()
$i = 1
foreach ($file in $fileNames)
    {
        Write-Host "[$i/$($filenames.count)] Importing $file."
        $strContent = Get-Content $file
        $headers = $strContent[0].split(',')
        $strContent = $strContent | Select -skip $SkipCount
        $output += ConvertFrom-Csv -InputObject $strContent -Header $headers
        $i++
    }

return $output
}