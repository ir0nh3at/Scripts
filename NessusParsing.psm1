function Import-XML {
    <#
        .DESCRIPTION
        Basic function that returns an XML formatted object from a file path.
        .PARAMETER FilePath
        String containing path to file.
        .NOTES
        Steve Custer <ir0nh3at@protonmail.com> - 12/12/2018
    #>
param(
    [Parameter(Mandatory=$true)]
    [String]$FilePath
    )

[xml]$output = Get-Content -Path $FilePath
return $output
}

function Get-NessusReportHost {
    <#
        .DESCRIPTION
        Lists hosts in Nessus report.  Takes either a File Path or an XML Object as input.
        .PARAMETER FilePath
        String containing path to input file.
        .PARAMETER XmlObject
        Object variable containing already-parsed XML of Nessus report.
        .NOTES
        Steve Custer <ir0nh3at@protonmail.com> - 12/12/2018
    #>
param(
    [String]$FilePath,
    [Xml]$XmlObject
    )

if (-not $FilePath -and -not $XmlObject)
    {
        Write-Error "You must specify either a file path or an XML object!"
        return -1
    }

if ($filePath -and $XmlObject)
    {
        Write-Error "You must specify ONLY ONE FilePath or XmlObject"
        return -1
    }

if ($FilePath)
    {
        [xml]$XmlObject = Get-Content -Path $FilePath
    }

return $XmlObject.NessusClientData_v2.Report.reporthost.name | sort

}

function Get-NessusReportItem {
    <#
        .DESCRIPTION
        Returns object containing Nessus Report Items.
        .PARAMETER HostNames
        Array of strings containing host names you're interested in.  If null all hosts will be returned.
        Note that a wildcard is thrown onto the end of the hostname, so "Computer" will find "Computer1" and "Computer2"
        but not "MyComputer" or "Server1".
        .PARAMETER FilePath
        String containing path to input file.
        .PARAMETER XmlObject
        Object variable containing already-parsed XML of Nessus report.
        .EXAMPLE
        Get-NessusReportItem -FilePath C:\temp\Client_Scan.nessus | where {$_.severity -eq 3}
        Return all high severity findings from the report.
        .EXAMPLE
        Get-NessusReportItem -FilePath C:\temp\Client_Scan.nessus -HostNames "Computer1","Computer2"
        Return all findings for Computer1 and Computer2.
        .NOTES
        Steve Custer <ir0nh3at@protonmail.com> - 12/12/2018
    #>

    param(
        [String]$FilePath,
        [Xml]$XmlObject,
        [String[]]$HostNames
        )
    
    if (-not $FilePath -and -not $XmlObject)
        {
            Write-Error "You must specify either a file path or an XML object!"
            return -1
        }
    
    if ($filePath -and $XmlObject)
        {
            Write-Error "You must specify ONLY ONE FilePath or XmlObject"
            return -1
        }
    
    if ($FilePath)
        {
            [xml]$XmlObject = Get-Content -Path $FilePath
        }

    if ($hostNames)
        {
            foreach ($hostName in $hostNames)
                {
                    $search = $hostName + "*"
                    $objReportHosts = $XmlObject.NessusClientData_v2.Report.ReportHost | where {$_.name -like $search}
                }
        }
        else
            {
                $objReportHosts = $XmlObject.NessusClientData_v2.Report.ReportHost
            }

    $output = @() #setting up output array.

    foreach ($objReportHost in $objReportHosts)
            {
                foreach ($reportItem in $objReportHost.ReportItem)
                    {
                        $properties = $($reportItem | get-member | where {$_.membertype -eq "Property"}).name
                        $loopOutput = New-Object -TypeName PSObject
                        $loopOutput | Add-Member -MemberType NoteProperty -Name "HostName" -Value $objReportHost.name
                        foreach ($property in $properties)
                            {
                                $loopOutput | Add-Member -MemberType NoteProperty -Name $property -Value $reportItem.$property
                            }

                    $output += $loopOutput
                    }
            }
    
    return $output
}