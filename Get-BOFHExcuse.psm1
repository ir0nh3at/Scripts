function Get-BOFHExcuse {
    <#
        .SYNOPSIS
            Gets a BOFH-style excuse from Jeff Ballard's BOFH server at http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl.
        .DESCRIPTION
            Gets a BOFH-style excuse from Jeff Ballard's BOFH server at http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl.
        .NOTES
            Laugh.  It's funny.  If you don't get it read: 
            Bastard Operator From Hell - Wikipedia  https://en.wikipedia.org/wiki/Bastard_Operator_From_Hell
            The Bastard Operator From Hell Complete http://bofh.bjash.com/
            Data Centre » BOFH • The Register https://www.theregister.co.uk/data_centre/bofh/
        .EXAMPLE
            Get-BOFHExcuse
            Gets a random excuse.
    #>

    $bofh = Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/bofhserver.pl -UseBasicParsing
    $excuse = $bofh.content.split('>')[11].split('<')[0]
    Write-Host "The problem is caused by: $excuse" -ForegroundColor Yellow

}