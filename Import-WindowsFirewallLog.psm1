function Import-windowsFirewallLog {
<#
    .DESCRIPTION
    Parses a windows firewall log and outputs a custom object.
    .PARAMETER LogPath
    Path to the file to parse.
    .NOTES
    Steve Custer <ir0nh3at@protonmail.com> 11/19/2018, last update 12/13/2018.
    Features I'd like to add at some point: feed text object directly, select -last whatever, drop only, accept only, progress bar.
#>
Param(
    [Parameter(Mandatory=$true)]
    [string]$logPath
)

$output = @() #setup output array.
$strLog = Get-Content $logPath | where {$_ -notlike "#*" -and $_.length -gt 1} #Have to check the length to filter out any blank lines, otherwise the get-date throws errors.


#Fields: date time action protocol src-ip dst-ip src-port dst-port size tcpflags tcpsyn tcpack tcpwin icmptype icmpcode info path
foreach ($line in $strLog)
    {
        $lineSplit = $line.split(' ')
        $output += New-Object -TypeName PSObject -Property @{
            Date = $lineSplit[0]
            Time = $lineSplit[1]
            Action = $lineSplit[2]
            Protocol = $lineSplit[3]
            SourceIP = $lineSplit[4]
            DestinationIP = $lineSplit[5]
            SourcePort = $lineSplit[6]
            DestinationPort = $lineSplit[7]
            Size = $lineSplit[8]
            TcpFlags = $lineSplit[9]
            TcpSyn = $lineSplit[10]
            TcpAck = $lineSplit[11]
            TcpWin = $lineSplit[12]
            IcmpType = $lineSplit[13]
            IcmpMode = $lineSplit[14]
            Info = $lineSplit[15]
            Path = $lineSplit[16]
            DateTimeObject = get-date "$($lineSplit[0]) $($lineSplit[1])" -ErrorAction SilentlyContinue
            }
    }

return $output
}