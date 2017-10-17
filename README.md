# PowerShell_Samples
Samples of my working knowledge of PowerShell

## ActiveModuleSync.ps1
* This script is in charge of mounting App-V packages one-by-one, until everything has been mounted. Logs are created to track mounting duration of the packages. Mounting will only occur if the computer does not currently have a user logged in and it has been idle for 10 minutes. This is set as a Scheduled Task.

## Set-RegKey.ps1
* This function is used as an alternative to Set-ItemProperty when adding and editing registry keys. Set-RegKey features the ability to use HKU as a drive in addition to HKLM. Also, if a key is not present when creating a property, it will be added automatically.

## eBookDL.ps1
  > MUST PERFORM FIRST-RUN USING INTERNET EXPLORER PRIOR TO USE
* This script is intended to be a helpful tool in acquiring the eBooks offered by Eric Ligman through the MSDN on July 11, 2017. Running this tool will automatically download and sort all eBooks that are available into their respective directories.

