Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

. "$PSScriptRoot\idle.ps1"

$statePath = "$PSScriptRoot\state.json"
$propertiesPath = "$PSScriptRoot\properties.json"


function Load-Properties {
	Get-Content $propertiesPath -Raw | ConvertFrom-Json
}

function Load-State {
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Save-State($state) {
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}

function Show-Balloon($text, $title = "Work Timer", $timeout = 5000) {
    $script:notifyIcon.BalloonTipTitle = $title
    $script:notifyIcon.BalloonTipText = $text
    $script:notifyIcon.ShowBalloonTip($timeout)
}

function Reset-State($state){
	$properties = Load-Properties
	
	$state.remainingSeconds = $properties.workPeriod
	$state.warned30 = $false
	$state.warned15 = $false
	$state.warned5 = $false
	$state.cooldown = $false
	$state.warnedIdle = $false
	$state.extendedIdle = $false
	
	if($state.lockOut -ne $properties.lockOut){
		$state.lockOut = $properties.lockOut
	}
	Save-State $state
}

$state = Load-State

if (-not $state.cooldownUntil -and $state.extendedIdle) {
	Show-Balloon "Computer was idle for more than 10 minutes.`nReseting work session."
    Reset-State $state    
} elseif (-not $state.cooldownUntil -and (-not $state.warnedIdle)){
	Reset-State $state
}