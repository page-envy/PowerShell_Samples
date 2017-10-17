# Set-RegKey.ps1  #
# Author: Nick Page    #
# Version: 1.0         #
# Date: 20 October 2015 #
#-------------------------------------------------------------------------------
# This function is used as an alternative to Set-ItemProperty when adding and 
# editing registry keys. Set-RegKey features the ability to use HKU as a drive
# in addition to HKLM. Also, if a key is not present when creating a property,
# it will be added automatically.
#-------------------------------------------------------------------------------
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

Function Set-RegKey{

<#
      .SYNOPSIS
          Creates a new entry in the registry based on the parameters used.
          Example -->    Set-RegKey -Drive* HKLM: -Path* .\Folder1 -Name* TestKey `
                                    -Property* newProperty -Type String `
                                    -PropertyValue testValue
                         * -> Denotes required parameters

      .PARAMETER Drive
          The desired registry drive to begin the path to the new key.
          Example -->    -Drive HKLM:

      .PARAMETER Path
          The location to store the new registry entry.
          Example -->    -Path .\Folder1\folder2

      .PARAMETER Name
          The name of the registry entry.
          Example -->    -Name NewKey

      .PARAMETER Property
          Name of the Property listed under the new registry key.
          Example -->    -Property newProperty

      .PARAMETER Type
          Type of property to be created.
          Example -->    -Type binary

      .PARAMETER PropertyValue
          Value of the new property created.
          Example -->    -PropertyValue 1

#>

param (
    [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]
    $Drive,

    [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]
    $Path,

    [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]
    $Name,

    [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()] [string]
    $Property,

    [string]
    $Type,

    [string]
    $PropertyValue

)
Push-Location
Set-Location $Drive
Test-Path $Path
if(!(Test-Path $Path\$Name)){
    New-Item -Path $Path -Name $Name -Force
}
$key = Get-Item -LiteralPath $path\$name
$keyTest = $key.GetValue($Property,$null)
if($PropertyValue){
  if($Type){
    if($keyTest -eq $null){
        New-ItemProperty -Path $Path\$Name -Name $Property -PropertyType $Type -Value $PropertyValue
    }
    else{
        Set-ItemProperty -Path $Path\$Name -Name $Property -Value $PropertyValue
    }
  }
  else{
    if($keyTest -eq $null){
        New-ItemProperty -Path $Path\$Name -Name $Property -Value $PropertyValue
    }
    else{
        Set-ItemProperty -Path $Path\$Name -Name $Property -Value $PropertyValue
    }
  }
}
else{
  New-ItemProperty -Path $Path\$Name -Name $Property
}
Pop-Location
}
