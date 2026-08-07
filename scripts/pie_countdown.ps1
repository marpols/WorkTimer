param(
    [int]$DurationSeconds,
    [int]$showPie,
    [int]$showTime,
    [int]$mainPID
)

# Load your globals/modules as usual
. "$PSScriptRoot\global_vars.ps1"

$files = Get-ChildItem -Path (Join-Path $parentDir "modules")
foreach ($file in $files) {
    Import-Module $file.FullName
}

Show-CountdownPie `
    -DurationSeconds $DurationSeconds `
    -showPie ([bool]$showPie) `
    -showTime ([bool]$showTime) `
    -mainPID $mainPID `
    -Wait