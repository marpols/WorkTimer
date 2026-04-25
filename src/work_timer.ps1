#Requires -Version 7.0

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

. "$PSScriptRoot/global_vars.ps1"
$src = @("utils.ps1", "state_func.ps1", "pause_func.ps1","properties.ps1", "exit_challenge.ps1", "idle.ps1")
foreach ($file in $src) {
    $path = Join-Path $parentDir "src" $file
	if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }
	. $path
}


$tbfrelock = 20000 #miliseconds (30s = 30000)


function Get-RemainingText($seconds, $verbose = $false) {
    $seconds = [math]::Max(0, [int]$seconds)
    $ts = [TimeSpan]::FromSeconds($seconds)
	$plural = $false
    if ($ts.Hours -gt 0) {
		if($verbose){
			$text = "{0} hour" -f $ts.Hours
			$plural = $ts.Hours -ne 1
		} else {
			return "{0}h {1}m" -f $ts.Hours, $ts.Minutes
		}
    } else {
		if ($ts.Minutes -lt 0) {
			if($verbose){
				$text = "{0}seconds" -f $ts.seconds
				} else {
					return "{0}s" -f $seconds
				}
		} else {
			if($verbose){
				$text = "{0} minute" -f $ts.Minutes
				$plural = $ts.Minutes -ne 1
			} else {
				return "{0}m" -f $ts.Minutes
			}
		}
	}
	if($plural){
		$text = $text + "s"
	}
	return $text
}

function Show-TimeLeft {
    $state = Load-State
    Save-State $state

    $pause = Get-PauseData
    $msg = "Time left in this Session: $(Get-RemainingText $state.remainingSeconds)"
	
	if ($properties.pomodoro){
		$msg += "`nPomodoro:  $($properties.numPomodoros - $state.pomNum + 1) out of $($properties.numPomodoros)"
	}
	
    if ($pause) {
        $until = [datetime]$pause.pauseUntil
        $msg += "`nPause active until: $($until.ToString('HH:mm'))"
    }

    if ($state.cooldownUntil) {
        $cool = [datetime]$state.cooldownUntil
        if ((Get-Now) -lt $cool) {
            $msg += "`nBreak until: $($cool.ToString('HH:mm'))"
        }
    }
	
	if ($state.emergencyUsed) {
		$emergency = [datetime]$state.emergencyUntil
		if ((Get-Now) -lt $emergency) {
			$msg += "`nEmergency unlock applied until: $($emergency.ToString('HH:mm'))"
		}
	}
	
	if (-not (Is-Scheduled) -or -not (In-WorkHours)){
		$msg = "Work Timer is running but not currently active."
	}

    Show-Message $msg "Work Timer Status"
}
$script:isExiting = $false

function Exit-App {
    if ($script:isExiting) {
        return
    }
	Start-Sleep -Milliseconds 150
    $passed = Show-ExitChallenge
    Add-Content "$parentDir\logs\debug.log" "Show-ExitChallenge returned: <$passed>"

    if (-not $passed) {
        Add-Content "$parentDir\logs\debug.log" "Exit cancelled"
        return
    }

    $script:isExiting = $true

    if ($script:timer) {
        $script:timer.Stop()
    }
    Cleanup-TrayIcon
    [System.Windows.Forms.Application]::Exit()
}

# Tray icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")
$script:notifyIcon.Text = "Work Timer"
$script:notifyIcon.Visible = $true

# Context menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$itemShow = $menu.Items.Add("Show time left")
$itemPause = $menu.Items.Add("Pause for 1 hour")
$itemResume = $menu.Items.Add("End pause now")
$itemProperties = $menu.Items.Add("Properties")
$itemExit = $menu.Items.Add("Exit")

$itemShow.Add_Click({ Show-TimeLeft })
$itemPause.Add_Click({ Pause-OneHour })
$itemResume.Add_Click({ Resume-Now })
$itemProperties.Add_Click({ Show-Properties })
$itemExit.Add_Click({ 
	if (($properties.eveningLO -and (In-EveningLockWindow)) -or ((Is-Scheduled) -and (In-WorkHours))){
		Exit-App 
	} else {
		if ($script:timer) {
        $script:timer.Stop()
		}
		Cleanup-TrayIcon
		[System.Windows.Forms.Application]::Exit()
	}
})

$itemEmergency = $menu.Items.Add("Emergency unlock (15 min)")
$itemEmergency.Add_Click({ powershell.exe -ExecutionPolicy Bypass -File "C:\WorkTimer\src\emergency_unlock.ps1" })

$script:notifyIcon.ContextMenuStrip = $menu
$script:notifyIcon.Add_DoubleClick({ Show-TimeLeft })

# Timer loop
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = $tbfrelock

$script:timer.Add_Tick({
    $state = Load-State
	
	$properties = Load-Properties
	
	$firstWarning = $properties.workPeriod * 0.25
	if ($firstWarning -gt 1800){$firstWarning = 1800} elseif($firstWarning -lt 300){$firstWarning = 120} else{$firstWarning = [Math]::Ceiling($firstWarning/300)*300}
	$secondWarning = $properties.workPeriod * 0.125
	if ($secondWarning -gt 900){$secondWarning = 900} elseif($firstWarning -eq 120){$secondWarning = 60} else{$secondWarning = [Math]::Ceiling($secondWarning/300)*300}
	if ($secondWarning -eq $firstWarning){$secondWarning = [Math]::Round($secondWarning)}
	$thirdWarning = $properties.workPeriod * 0.0417
	if ($thirdWarning -gt 300){$thirdWarning = 300} elseif($secondWarning -eq 60){$thirdWarning = 30} else{$thirdWarning = [Math]::Ceiling($thirdWarning/300)*300}
	if ($thirdWarning -eq $secondWarning){$thirdWarning = [Math]::Round($thirdWarning)}

    $now = Get-Now
    $lastTick = [datetime]$state.lastTick
    $elapsed = [math]::Max(0, [int]($now - $lastTick).TotalSeconds)

	
	if ($state.emergencyUntil) {
		$emergencyUntil = [datetime]$state.emergencyUntil
		if ((Get-Date) -lt $emergencyUntil) {
			$state.lastTick = (Get-Date).ToString("o")
			Save-State $state
			return
		} else {
			$state.emergencyUntil = $null
		}
	}
	
	if ($properties.eveningLO -and (In-EveningLockWindow)) {

		if (Pause-Active) {
			# Allow temporary override for meetings
			return
		}
		
		if (-not $state.eveningNotified) {
			$endTime = Str-to-Date($properties.endTime)
			Show-Message "Workday ended! You can come back at $($endTime.AddMinutes($properties.duration).ToString('HH:mm')) if needed otherwise gtfo." "Work Timer"
			$state.eveningNotified = $true
			}

		Lock-PC
		return
	}

    if (Pause-Active) {
        $state.lastTick = $now.ToString("o")
        Save-State $state
        return
    }
	
	if ($(Is-Idle 3) -and (-not $state.cooldown)){
		if (-not $state.warnedIdle){
			Show-Balloon "Computer has been idle for 3 minutes. Pausing timer." "Work Timer"
			$state.warnedIdle = $true
		}
		if (Is-Idle 10){
			$state.extendedIdle = $true
		}
		$state.lastTick = $now.ToString("o")
		Save-State $state
		return
	} else {
		$state.warnedIdle = $false
	}

    if ($state.cooldownUntil) {
        $cooldownUntil = [datetime]$state.cooldownUntil
        if ($now -lt $cooldownUntil) {
            Lock-PC
            $state.lastTick = $now.ToString("o")
            Save-State $state
            return
        } else {
            $state.cooldownUntil = $null
        }
    }
	
	if (-not (In-WorkHours)) {
        $state.lastTick = $now.ToString("o")
        Save-State $state
        return
    }

    $state.remainingSeconds -= $elapsed
    if ($state.remainingSeconds -lt 0) { $state.remainingSeconds = 0 }

    if (-not $state.warned30 -and $state.remainingSeconds -le $firstWarning -and $state.remainingSeconds -gt $secondWarning) {
        Show-Balloon "$(Get-RemainingText $state.remainingSeconds $true) left." "Work Timer"
        $state.warned30 = $true
    }

    if (-not $state.warned15 -and $state.remainingSeconds -le $secondWarning -and $state.remainingSeconds -gt $thirdWarning) {
        Show-Message "$(Get-RemainingText $state.remainingSeconds $true) left. Start wrapping up." "Work Timer"
        $state.warned15 = $true
    }
	
	if (-not $state.warned5 -and $state.remainingSeconds -le $thirdWarning -and $state.remainingSeconds -gt 0) {
		if ($thirdWarning -eq 30){
			$timetext = "30 seconds"
		} else {
			$timetext = "$(Get-RemainingText $state.remainingSeconds $true)"
		}
        Show-Message "$timetext left. Save your work now and write next steps." "Work Timer"
        $state.warned5 = $true
    }

    if (-not $state.cooldown -and $state.remainingSeconds -le 0) {
		if ($properties.pomodoro){
			if($state.pomNum -gt 1){
				$lockoutTime = $properties.shortBreak
				$state.pomNum -= 1
			} else {
				$lockoutTime = $properties.lockOut
			}
		} else {
			$lockoutTime = $properties.lockOut
		}
		Show-Message "Time is up. The computer will lock now. Cooldown: $($lockoutTime) minutes." "Work Timer"	
        $state.cooldownUntil = $now.AddMinutes($lockoutTime).ToString("o")
		$state.cooldown = $true
        Lock-PC
    }

    $state.lastTick = $now.ToString("o")
    Save-State $state
})

$properties = Load-Properties

# Start
Set-State
if ($properties.pomodoro){
	$msg = "Work Timer is running`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nNumber of Pomodoros: $($properties.numPomodoros)`nWork for $(Get-RemainingText $properties.workPeriod $true)`nShort breaks for $($properties.shortBreak) minute(s)`nLong breaks for $($properties.lockOut) minutes."
} else {
	$msg = "Work Timer is running`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nWork for $(Get-RemainingText $properties.workPeriod $true) `nBreaks for $($properties.lockOut) minutes."
}
if ($properties.eveningLO){
	$msg += "`nEvening Lockout enabled for $($properties.duration) minutes"
}
Show-Balloon $msg 
$script:timer.Start()

[System.Windows.Forms.Application]::Run()