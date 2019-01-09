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


function Create-SCCMRemediationCollectionsFromNessus {
    <#
        .DESCRIPTION
        This function takes the top findings from a .nessus report file and creates SCCM device collections with the affected machines.  This allows the
        administrator to easily apply remediations to just the affected machines.  If the collection already exists, the affected hosts are added to
        the existing collection.  Requires the SCCM PS module as well as my Import-XML and Get-NessusReportItem functions, which should be included 
        in this module.
        .SYNOPSIS
        This function takes the top findings from a .nessus report file and creates SCCM device collections with the affected machines.
        .PARAMETER FilePath
        The path to the .nessus file to parse.  Can also be multiple files.
        .PARAMETER LimitingCollectionName
        The name of the limiting collection for the created device collections.  Defaults to "All Systems".
        .PARAMETER TopFindingsToInclude
        The top number of findings to create collections for.  Defaults to 5.
        .PARAMETER MinSeverityToInclude
        Items of this severity and greater will be included in your calculations.  Defaults to 3 (HIGH).  I don't recommend setting this any lower than
        2 (Medium).
        .PARAMETER SiteCode
        Override the default SCCM Site Code.  This shouldn't be necessary; the function runs "Get-PSDrive -PSProvider CMSITE" to detect it automagically.
        Example: "PRI"
        .PARAMETER CollectionFolderPath
        This is the path that the collections will be moved to.  Make sure it exists; the script doesn't create it automatically at this time.
        Defaults to the base "Device Collections" folder.  Example: "\Security\Remediation" will put the collections in "Device Collections\Security\Remediation".
        .PARAMETER DomainName
        The name of the domain of the computers in the file.  Defaults to the domain of the computer running the function.  This is needed to ensure we're\
        attempting to add computers that are probably in SCCM, and to filter out hosts that Nessus only identifies by IP.  Example:"domain.com"
        If you want to attempt to bypass this (expect errors), specify "*".
        .EXAMPLE
        Create-SCCMRemediationCollectionsFromNessus -FilePath C:\temp\Austin.nessus
        Creates remediation groups from the top five findings of "High" or greater from the file c\temp\Austin.nessus in the default Device Collections folder.
        .EXAMPLE
        Create-SCCMRemediationCollectionsFromNessus -FilePath C:\temp\Shanghai.nessus -limitingCollectionName "All Windows Workstation or Professional Systems" -CollectionFolderPath "\Security\Remediation Collections"
        Creates remediation groups from the top five findings of "High" or greater from the file c:\temp\Shanghai.nessus in the "Device Collections\Security\Remediation Collections" folder.
        .NOTES
        * At this time, the check for the configuration manager function won't work if you're on an imported session.  Comment out that line to bypass.
        * Due to length limitations, the creation of the Device Collections fails if the comment field is too long.  I've truncated the info in there, but
        you may want to edit the definition of the $comment variable to include less information if you have failures there.
        Steve Custer <ir0nh3at@protonmail.com> - v1.0 - 1/9/2019
    #>
    
    param(
        [String]$limitingCollectionName = "All Systems",
        [String]$SiteCode,
        [String]$CollectionFolderPath,
        [int32]$TopFindingsToInclude = 5,
        [int32]$MinSeverityToInclude = 3,
        [String]$DomainName = $(Get-WmiObject win32_computersystem).domain,
        [Parameter(Mandatory=$true)]
        [String[]]$FilePath
    
    )
    
    #$FilePath = "u:\temp\Columbus.Nessus"
    #$TopFindingsToInclude = 5
    #$minSeverityToInclude = 3
    #"SIT:\DeviceCollection\Security\Remediation Collections"
    #$limitingCollectionName = "All Windows Workstation or Professional Systems"
    
    #Test for SCCM Module, bail if missing.
    if (!$(Get-Module ConfigurationManager)){Write-Error "Configuration Manager module not loaded.  Load it before running this function." ; return -1}
    
    if (!$SiteCode){$SiteCode = $(Get-PSDrive -PSProvider CMSITE).Name} #Find site code if not provided.
    if ($CollectionFolderPath){$CollectionFolderPath = $SiteCode + ":\DeviceCollection" + $collectionFolderPath} #If the collection folder path has been provided, reformat.
    
    $formattedDate = get-date -format "MM/dd/yy HH:mm:ss" #This is used in the comment field of the new collection.
    Push-Location $SiteCode":" #You have to be in the SCCM drive to run this stuff (technically, I know there's a workaround, but let's keep it simple)
    
    $items = Get-NessusReportItem -FilePath $FilePath | where {$_.severity -ge $minSeverityToInclude} #Populate array with all items from the .nessus report.
    $topPlugins = ($items | Sort-Object PluginId).pluginId | Group-Object | Sort-Object -Descending Count | select -First $TopFindingsToInclude #Collects the top X findings.
    
    $createItems = @()
    
    #This loop collects one example of a finding by each of the top plugins.
    foreach ($plugin in $topPlugins)
        {
            $createItems += $items | where {$_.pluginID -eq $plugin.Name} | select -First 1
        }
    
    #From each of those examples, we'll create the device collections.  The naming is straight-forward enough that we shouldn't have any duplicate collections
    #even after multiple runs.
    
    foreach ($item in $createItems)
        {
            $CollectionName = $item.pluginId + " - " + $item.risk_factor + " - " + $item.pluginName
            $objCollection = @()
            $objCollection = Get-CMCollection -Name $CollectionName
            
            #If the collection doesn't already exist, create it.
            if (!$objCollection)
                {
                    #If you're running into SQL errors creating the collections, this is the first place I'd look.  You'll note that I trimmed
                    #the Microsoft ID and Nessus' See Also URLs way back to avoid it.
                    $comment = "Auto-generated $formattedDate",
                                "Synopsis: $($item.synopsis)",
                                "Microsoft ID: $($item.msft.split(' ') | select -first 2)",
                                "See also: $($item.see_also.split([environment]::newline) | select -first 2)",
                                "Severity: $($item.severity) / $($item.risk_factor)"
                    $comment = $comment | out-string
    
                    Write-Host "Creating $CollectionName"
                    New-CMDeviceCollection -Name $CollectionName -Comment $comment -LimitingCollectionName $limitingCollectionName -RefreshType Continuous
                    $objCollection = Get-CMCollection -Name $CollectionName
                    if ($CollectionFolderPath){Move-CMObject -FolderPath $CollectionFolderPath -InputObject $objCollection} #If an alternate path has been specified, move the collection.
                }
            
            #Recheck for collection existence and write error if it's missing.  This will let us skip trying to add members to a non-existent collection.
            $objCollection = Get-CMCollection -Name $CollectionName
            if (!$objCollection)
                {
                    Write-Host "ERROR: $CollectionName not found!  Continuing..."
                    continue
                }
                else
                    {
                        $vulnHosts = ($items | where {$_.pluginId -eq $item.pluginId}).hostname | where {$_ -like "*.$domainName"} | % {$_.split('.')[0]} #adds the part of the host before the "." to an array.
                        $vulnHosts | % {Add-CMDeviceCollectionDirectMembershipRule -CollectionId $objCollection.CollectionId -ResourceId $(Get-CMDevice -Name $_).resourceId -erroraction SilentlyContinue} #adds each to the collection.
                    }
        }
    Pop-Location #return to previous location.
}