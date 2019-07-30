function Convert-GoogleChromeExtensionIdToName {

    <#
        .SYNOPSIS
            Makes an HTML query to Google to identify the friendly name of a Chrome extension ID.  Returns custom object with Name and ExtensionId.
        .DESCRIPTION
            Makes an HTML query to Google to identify the friendly name of a Chrome extension ID.  Returns custom object with Name and ExtensionId.
        .PARAMETER ExtensionId
            Google Chrome Extension Id.
        .EXAMPLE
            Convert-GoogleChromeExtensionIdToName -extensionId eimadpbcbfnmbkopoojfekhnkhdbieeh
            ExtensionId                      Name
            -----------                      ----
            eimadpbcbfnmbkopoojfekhnkhdbieeh Dark Reader
        .EXAMPLE
            gci "C:\Users\UserName\AppData\Local\Google\Chrome\User Data\Default\Extensions" | % {Convert-GoogleChromeExtensionIdToName -extensionId $_.basename}
            ExtensionId                      Name
            -----------                      ----
            aapocclcgogkmnckokdopfmhonfmgoek Slides
            aohghmighlieiainnegkcijnfilokake Docs
            apdfllckaahabafndbhieahigkjlhalf Google Drive
            blpcfgokakmgnkcojhhkbfbldkacnbeo YouTube
            eimadpbcbfnmbkopoojfekhnkhdbieeh Dark Reader
            felcaaldnbdncclmgdcncolpebgiejap Sheets
            ghbmnnjooekpmoecnnnilnnbdlolhkhi Google Docs Offline
            nmmhkkegccagdldgiimedpiccmgmieda ERROR: nmmhkkegccagdldgiimedpiccmgmieda returned code NotFound  Visit https://chrom...
            pjkljhegncpnkpknbcohdijeoejaedia Gmail
            pkedcjkdefgpdelpbcmbmeomcjbeemfm ERROR: pkedcjkdefgpdelpbcmbmeomcjbeemfm returned code NotFound  Visit https://chrom...
            Temp                             ERROR: Temp returned code NotFound  Visit https://chrome.google.com/webstore/detail...
        .NOTES
            Steve Custer 7/30/2019
    #>
    
    param (
        [parameter(Mandatory=$true)]
        [string]$extensionId
        )

    $ChromeWebStoreBaseURL = "https://chrome.google.com/webstore/detail/"
    $extensionURL = $ChromeWebStoreBaseURL + $extensionId
    try {
            $response = Invoke-WebRequest $extensionURL
        
            if ($response.statusCode -eq 200)
                {
                    return New-Object -TypeName PSOBject -Property @{
                    Name = $response.parsedhtml.title.replace(' - Chrome Web Store','')
                    ExtensionId = $extensionId
                    }
                }
                else
                    {
                        return New-Object -TypeName PSOBject -Property @{
                            Name = "ERROR: $ExtensionId not found or returned error.  Visit $extensionURL to troubleshoot."
                            ExtensionId = $extensionId
                            }              
                    }
        }
        catch {
            $response = $_.exception.Response
            return New-Object -TypeName PSOBject -Property @{
                Name = "ERROR: $ExtensionId returned code $($response.statuscode)  Visit $extensionURL to troubleshoot."
                ExtensionId = $extensionId
                }
        }
    }