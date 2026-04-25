$parentDir = Split-Path -Path $PSScriptRoot -Parent
$statePath = "$parentDir\json\state.json"
$propertiesPath = "$parentDir\json\properties.json"
$pausePath = "$parentDir\json\pause.json"
$difficulty = @{
	0 = "Easy"
	1 = "Medium"
	2 = "Hard"
}