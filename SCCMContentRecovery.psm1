function Recover-SCCMPackageContentFromDP {
<#
    .DESCRIPTION
    Recovers lost package content easily from an SCCM deployment point.  No error checking implemented.  https://www.youtube.com/watch?v=-crgQGdpZR0
    .PARAMETER https
    Specifies that https be used to connect to DP.
    .PARAMETER DistributionPoint
    FQDN for DP (ie. distributionpoint.contoso.com).  Use the SCCM console to verify that the content you want is hosted there.
    .PARAMETER ContentID
    Content ID of the files you're trying to recover.  For example, CON00123.
    .PARAMETER CertificateThumbPrint
    The Thumbprint of a certificate you have installed that has access to the DP, if you're set up that way.  In testing
    I had to export the machine cert and import it into my Personal store.
    .PARAMETER OutputDirectory
    The location that the files will be placed.  Defaults to current location.
    .EXAMPLE 
    Recover-SCCMPackageContentFromDP -Https -DistributionPoint "distributionpoint.contoso.com" -ContentId CON00123 -OutputDirectory C:\temp\packages\ -CertificateThumbPrint "db402ae3008c6db5b6dad0d86534a12d0672f3e8"
        Directory: C:\temp\packages
    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----        3/27/2019   2:48 PM                CON00123
    https://distributionpoint.contoso.com/SMS_DP_SMSPKG$/CON00123.2/smscachesize.vbs

    .NOTES
    Steve Custer <ir0nh3at@protonmail.com> - 3/27/2019
#>

    param(
        [Switch]$Https,
        [String]$CertificateThumbPrint,
        [String]$OutputDirectory=$(Get-location),
        [Parameter(Mandatory=$true)]
        [String]$ContentId,
        [String]$DistributionPoint
    )    

#CertificateThumbprint is thumbprint of machine client auth certificate.  Required for https.

if ($https){$protocol = "https"}
    else {$protocol = "http"}
$uri = $protocol + "://" + $DistributionPoint + "/SMS_DP_SMSPKG$/" + $contentID
$body = Invoke-WebRequest $uri -CertificateThumbprint $CertificateThumbPrint
$links = $body.links.innerHtml
if (Test-Path $OutputDirectory\$ContentID)
    {Write-Output "ERROR: $outputDirectory\$contentID already exists!" ; Return 9}
md $OutputDirectory\$ContentID
foreach ($link in $links)
    {
        $linkComponents = $link.split('/')
        $outFileName = "$OutputDirectory\$ContentID\$($linkComponents[$linkComponents.length -1])"
        #This is stupid, but the https site returns http links that don't work in some configs.
        if ($https)
            {$link = $link.replace('http','https')}
        WRite-host $link
        Invoke-WebRequest -Uri $link -OutFile $outFileName -CertificateThumbprint $CertificateThumbPrint}
}


function Recover-SCCMapplicationContentFromDP {
<#
    .DESCRIPTION
    Recovers lost application content easily from an SCCM deployment point.  No error checking implemented.  https://www.youtube.com/watch?v=-crgQGdpZR0
    Needs work - currently doesn't handle content with subfolders.
    .PARAMETER https
    Specifies that https be used to connect to DP.
    .PARAMETER DistributionPoint
    FQDN for DP (ie. distributionpoint.contoso.com).  Use the SCCM console to verify that the content you want is hosted there.
    .PARAMETER ContentID
    Content ID of the files you're trying to recover.  For example, CON00123.
    .PARAMETER CertificateThumbPrint
    The Thumbprint of a certificate you have installed that has access to the DP, if you're set up that way.  In testing
    I had to export the machine cert and import it into my Personal store.
    .PARAMETER OutputDirectory
    The location that the files will be placed.  Defaults to current location.
    .EXAMPLE 
    Recover-SCCMApplicationContentFromDP -Https -DistributionPoint "distributionpoint.contoso.com" -ContentId CON00123 -OutputDirectory C:\temp\apps\ -CertificateThumbPrint "db402ae3008c6db5b6dad0d86534a12d0672f3e8"
        Directory: C:\temp\apps

    Mode                LastWriteTime         Length Name
    ----                -------------         ------ ----
    d-----        3/27/2019   3:05 PM                CON00123
    https://distributionpoint.contoso.com/SMS_DP_SMSPKG$/Content_29d536a4-bd7c-45db-be6d-855f7c53a053.1/vcredist_x64.exe
    .NOTES
    Steve Custer <ir0nh3at@protonmail.com> - 3/27/2019
#>    
    
    param(
        [Switch]$Https,
        [String]$CertificateThumbPrint,
        [String]$OutputDirectory=$(Get-location),
        [Parameter(Mandatory=$true)]
        [String]$ContentId,
        [String]$DistributionPoint
    )

#CertificateThumbprint is thumbprint of machine client auth certificate.  Required for https.

if ($https){$protocol = "https"}
    else {$protocol = "http"}

$contentIni = "\\" + $DistributionPoint + "\SCCMContentLib$\pkglib\" + $ContentId + ".ini"
$applicationContent = Get-Content $contentIni
$contentGuid = $applicationContent | where {$_ -like "Content_*"}
$contentGuids = $contentGuid.replace('=','')
if (Test-Path $OutputDirectory\$ContentID)
        {Write-Output "ERROR: $outputDirectory\$contentID already exists!" ; Return 9}
md $OutputDirectory\$ContentID
foreach ($contentGuid in $contentGuids)
    {
    $uri = $protocol + "://" + $DistributionPoint + "/SMS_DP_SMSPKG$/" + $contentGuid
    $body = Invoke-WebRequest $uri -CertificateThumbprint $CertificateThumbPrint
    $links = $body.links.innerHtml
    
    foreach ($link in $links)
        {
            $linkComponents = $link.split('/')
            $outFileName = "$OutputDirectory\$ContentID\$($linkComponents[$linkComponents.length-1])"
            #This is stupid, but the https site returns http links that don't work in some configs.
            if ($https)
                {$link = $link.replace('http','https')}
            Write-host $link " => " $outFileName
            Invoke-WebRequest -Uri $link -OutFile $outFileName -CertificateThumbprint $CertificateThumbPrint}
    }
}