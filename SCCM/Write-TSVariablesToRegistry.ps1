#Write-TSVariablesToRegistry.ps1
#Saves TS variables to registry.  Useful for future troubleshooting and targeting.
#Notably the _SMSTSPackageName which will have the version info of the TS.

$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment #Create COM Object
# $tsvars = $tsenv.GetVariables() #Put TS variable names into variable. Uncomment to get *all* variables (slows the script).

# these are the ones we're actually interested in, in general:
$tsvars = "_OSDOSImagePackageId",
"_OSDProtectHardLinkStore",
"_SMSTSAdvertID",
"_SMSTSBootImageID",
"_SMSTSLogPath",
"_SMSTSMachineName",
"_SMSTSMP",
"_SMSTSPackageName",
"IsVirtual",
"IsLaptop",
"IsDesktop",
"_SMSTSUserStarted",
"OSArchitecture",
"OSDAdapter0MACAddress",
"OSDAdapter0Name",
"OSDComputerName"

$registryPath = "HKLM:\Software\OSD" #This is the key the values will be written to.

if (!(Test-Path $registryPath))
        {New-Item -Path $registryPath -Force} # Check if InstallFlags path exists and creates if not.
  
#Iterate through and write a value for each TS variable
foreach ($var in $tsvars)
 {
  New-ItemProperty -Path $registryPath -Name $var -Value $tsenv.value($var) -PropertyType String -Force
 }