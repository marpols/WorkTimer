Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

. "$PSScriptRoot/global_vars.ps1"
if (-not $parentDir) {
    throw "`$parentDir was not set by global_vars.ps1"
}
. "$PSScriptRoot/idle.ps1"

Write-Host $PSScriptRoot

#load modules
$files = Get-childItem  -path $(Join-Path $parentDir "modules")
foreach ($file in $files.Name) {
    $path = Join-Path $parentDir "modules" $file
	if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }
	Import-Module $path
}
Write-Host "Test script propertiesPath: $propertiesPath"

$properties = Load-Properties

Show-Properties

