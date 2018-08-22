# Snippets
# This file is a collection of snippets that don't rate their own files
# Steve Custer - Last Update 8/22/18

return 0 #just in case someone accidentally runs the file.

###
# Pipe results of Get-GPPPassword into Get-GPO to easily find name of vulnerable policies:
$pw = Get-GPPPassword
$pw | where {$_.passwords -ne "[BLANK]"} | % {get-gpo -Guid $_.file.substring(37,36)} | select displayname, gpostatus, id

###
# Update ACL for a bunch of folders, without affecting the root folder itself.
$rootPath = "\\server\share"
$folders = gci $rootPath | where {$_.PSIsContainer}
$ACL_Modify = "Domain\UserOrGroup","FullControl","ContainerInherit,ObjectInherit","None","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ACL_Modify
$i = 1
$count = $folders.count
foreach ($folder in $folders)
    {
        Write-Host "[$i/$count] " -ForegroundColor Yellow -NoNewline
        Write-Host "Applying ACL to $($folder.fullname)."
        $acl = Get-Acl $folder.FullName
        $acl.AddAccessRule($accessRule)
        $acl | Set-Acl $folder.FullName
    }

    ###