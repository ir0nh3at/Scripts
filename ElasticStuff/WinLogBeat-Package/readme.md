WinLogBeat-Package

How to use these files to create an installable multi-site package:

- Create a top level folder (something like \\server\share\elastic\WinlogBeat)
- Download and extract the winlogbeat-7.2.0-windows-x86_64 folder from the zip to that folder (\\server\share\elastic\WinlogBeat\winlogbeat-7.2.0-windows-x86_64)
- Copy your configs to the \\server\share\elastic\WinlogBeat\winlogbeat-7.2.0-windows-x86_64\configs with the name <site>.yml.  Use default.yml as your default.
- Copy Install-WinLogBeat.ps1 to \\server\share\elastic\WinlogBeat\
- Copy Uninstall-WinLogBeat.ps1 to the \\server\share\elastic\WinlogBeat\winlogbeat-7.2.0-windows-x86_64\ folder.
- Copy WinLogBeat.ico to the \\server\share\elastic\WinlogBeat\winlogbeat-7.2.0-windows-x86_64\ folder.
- Create the package in the tool of your choice.
    - Content path is "\\server\share\elastic\WinlogBeat\"
    - Use "powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File .\Install-WinLogBeat.ps1 -Site LON" as your install command line.
        - The above example will install the service with LON.yml as the config.
        - If you omit the -Site parameter, default.yml will be used.
    - Use "powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -File 'C:\Program Files\winlogbeat-7.2.0-windows-x86_64\uninstall-winlogbeat.ps1'" as your uninstall command line.
- For a detection method, I chose to use the registry entry for the beginning of the service.  This way if accidentally try to install two configs to the same site, it'll recognize it's already installed.
    - In SCCM it's a registry path, "SYSTEM\CurrentControlSet\Services\winlogbeat\ImagePath", the Operator is "Begins With" and the value is <"C:\Program Files\winlogbeat-7.2.0-windows-x86_64\winlogbeat.exe> (including the double quote at the beginning, but not the end)


The package also adds an entry to add/remove programs to allow easy uninstallation.

SC - 7/11/2019