function Get-Now {
    Get-Date
}

function Str-to-Date($dateStr){
	return [datetime]::Parse($dateStr)
}

function Is-Scheduled {
	$state = Load-State
    $day = (Get-Now).DayOfWeek
	
    return $day -in $state.days
}

function In-WorkHours {
	$state = Load-State
    $now = Get-Now
    $start = Str-to-Date($state.startTime)
    $end   = Str-to-Date($state.endTime)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function In-EveningLockWindow {
	$properties = Load-Properties
    $now = Get-Date
    $start = Str-to-Date($properties.endTime)
    $end   = $start.AddMinutes($properties.duration)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function Get-RemainingText($seconds, $verbose = $false) {
    $seconds = [math]::Max(0, [int]$seconds)
    $ts = [TimeSpan]::FromSeconds($seconds)
	function is-plural($text){
		return $text + "s"
	}
    if ($ts.Hours -gt 0) {
		if($verbose){
			$text = "{0} hour" -f $ts.Hours
			if ($ts.Hours -ne 1){$text = is-plural $text}
			if($ts.Minutes -gt 0){
				$mintext = " {0} minute" -f $ts.Minutes
				if ($ts.Minutes -ne 1){$mintext = is-plural $mintext}
				$text += $mintext
			}
		} else {
			return = "{0}h {1}m" -f $ts.Hours $ts.Minutes
		}
    } else {
		if ($ts.Minutes -le 0) {
			if($verbose){
				$text = "{0} second" -f $ts.Seconds
				if ($ts.Seconds -ne 1){$text = is-plural $text}
				} else {
					return "{0}s" -f $seconds
				}
		} else {
			if($verbose){
				$text = "{0} minute" -f $ts.Minutes
				if ($ts.Minutes -ne 1){$text = is-plural $text}
			} else {
				return "{0}m" -f $ts.Minutes
			}
		}
	}
	return $text
}

function Lock-PC {
    rundll32.exe user32.dll,LockWorkStation
}