function Copy-SCCMTaskSequenceToSourceControl {
    <#
	.SYNOPSIS
		Exports an SCCM Task Sequence to Source Control.
	.DESCRIPTION
        Requires an already-cloned git repository, correctly configured git, SCCM Module, etc.
        NO ERROR CHECKING OR SANITY CHECKING IS BEING DONE AT THIS TIME!

        To restore: select all files and folders in subdirectory except README.md and use 7-zip to
        create a new zip.  Then, import into SCCM.  (for some reason Compress-Archive doesn't leave
        the zip readble to SCCM.  Haven't tried the 7z command line yet).

        v1.1 - Steve Custer - 8/10/2018

	.EXAMPLE
		Copy-SCCMTaskSequenceToSourceControl -ClonePath P:\git\TS_Win7x64_Prod\ -PackageID PRI0029F
		Exports the task sequence to p:\git\TS_Win7x64_Prod and commits to source control.
    .PARAMETER ClonePath
        This is the path to the clone of the repository.
    .PARAMETER PackageId
        This is the SCCM PackageId of the Task Sequence.
    .PARAMETER tempPath
        If you want to override the system default temporary path, you can do so here.
    .PARAMETER siteCode
        The site code of the SCCM site.
    #>    
    
    param (
        [string]$tempPath = $env:TEMP,
        [Parameter(Mandatory=$true)]
        [string]$ClonePath,
        [string]$PackageID,
        [string]$siteCode
    )

    Write-Warning -Message "No error checking is implemented in this function yet."
    Push-Location $sitecode`:\ #Required for SCCM cmdlets
    $tsInfo = Get-CMTaskSequence -Id $PackageID
    $zipPath = $tempPath + "\" + $PackageID + ".zip" #Path for temporary zip file

    Export-CMTaskSequence -TaskSequencePackageId $PackageID -ExportFilePath $zipPath -WithDependence $false -WithContent $false
    Expand-Archive $zipPath $ClonePath -Force
    Remove-Item $zipPath -Force #Cleanup zip file
    Pop-Location
    Push-Location $ClonePath
    $readmePath = ".\README.md"
    
    "`n--------" | Add-Content $readmePath
    "Info as of $(get-date -Format yyyyMMdd_HHmmss):"  | Add-Content $readmePath
    "Name: $($tsInfo.Name)" | Add-Content $readmePath
    "PackageId: $($tsinfo.PackageId)" | Add-Content $readmePath
    "Description: $($tsinfo.Description)" | Add-Content $readmePath
    "LastRefreshTime: $($tsinfo.LastRefreshTime)" | Add-Content $readmePath
    "BootImageID: $($tsinfo.BootImageID)" | Add-Content $readmePath
    git add . #Add all files to commit.
    git commit -m "$packageid - $($tsInfo.name)"
    git push

    Pop-Location
}