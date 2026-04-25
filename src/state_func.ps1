function Set-State {
	$properties = Load-Properties
	$state = @{
		remainingSeconds = $properties.workPeriod
		warned30 = $false
		warned15 = $false
		warned5 = $false
		warnedIdle = $false
		extendedIdle = $false
		cooldown = $false
		cooldownUntil = $null
		lastTick = (Get-Now).ToString("o")
		lastDate = (Get-Now).ToString("yyyy-MM-dd")
		eveningNotified = $false
		emergencyUsed = $false
		emergencyUntil = $null
		pomNum = $properties.numPomodoros
	}
	$state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}

function Load-State {
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Save-State($state) {
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}