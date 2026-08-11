$global:parentDir = Split-Path -Path $PSScriptRoot -Parent
$global:statePath = "$parentDir\json\state.json"
$global:propertiesPath = "$parentDir\json\properties.json"
$global:pausePath = "$parentDir\json\pause.json"
$global:difficulty = @{
	0 = "Easy"
	1 = "Medium"
	2 = "Hard"
}