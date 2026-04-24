Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

. "$PSScriptRoot\properties.ps1"
. "$PSScriptRoot\exit_challenge.ps1"
. "$PSScriptRoot\idle.ps1"

$statePath = "$PSScriptRoot\state.json"
$propertiesPath = "$PSScriptRoot\properties.json"
$pausePath = "$PSScriptRoot\pause.json"


$tbfrelock = 20000 #miliseconds (30s = 30000)


function Get-Now {
    Get-Date
}

function Str-to-Date($dateStr){
	return [datetime]::Parse($dateStr)
}

function Load-Properties {
	Get-Content $propertiesPath -Raw | ConvertFrom-Json
}

function Save-Properties($properties) {
    $properties | ConvertTo-Json | Set-Content $propertiesPath -Encoding UTF8
}

function Is-Scheduled {
	$properties = Load-Properties
    $day = (Get-Now).DayOfWeek
	
    return $day -in $properties.days
}

function In-WorkHours {
	$properties = Load-Properties
    $now = Get-Now
    $start = Str-to-Date($properties.startTime)
    $end   = Str-to-Date($properties.endTime)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function In-EveningLockWindow {
	$properties = Load-Properties
    $now = Get-Date
    $start = Str-to-Date($properties.endTime)
    $end   = $start.AddMinutes($properties.duration)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function Ensure-State {
	$properties = Load-Properties
	$state = @{
		remainingSeconds = $properties.workPeriod
		lockOut = $properties.lockOut
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
	}
	$state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}

function Load-State {
    #Ensure-State
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Save-State($state) {
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}


function Get-PauseData {
    if (-not (Test-Path $pausePath)) {
        return $null
    }

    try {
        $pause = Get-Content $pausePath -Raw | ConvertFrom-Json
        $until = [datetime]$pause.pauseUntil
        if ((Get-Now) -lt $until) {
            return $pause
        } else {
            Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
            return $null
        }
    } catch {
        Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
        return $null
    }
}

function Pause-Active {
    return $null -ne (Get-PauseData)
}

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

function Show-Message($text, $title = "Work Timer", $type = 'Warning') {
   [System.Windows.Forms.MessageBox]::Show(
    $text,
    $title,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning,
	[System.Windows.Forms.MessageBoxDefaultButton]::Button1,
	[System.Windows.Forms.MessageBoxOptions]::ServiceNotification
	)
}

function Show-Balloon($text, $title = "Work Timer", $timeout = 5000) {
	$script.notifyIcon.Icon = New-Object System.Drawing.Icon("$PSScriptRoot\time.ico")
    $script:notifyIcon.BalloonTipTitle = $title
    $script:notifyIcon.BalloonTipText = $text
    $script:notifyIcon.ShowBalloonTip($timeout)
}

function Lock-PC {
    rundll32.exe user32.dll,LockWorkStation
}

function Pause-Timer {
	$pause = @{
		pauseUntil = (Get-Date).AddHours(1).ToString("o")
	}
    $pause | ConvertTo-Json | Set-Content $pausePath -Encoding UTF8
}

function Resume-Timer {
    if (Test-Path $pausePath) {
        Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
		return $true
	}
	return $false
}

function Pause-OneHour {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $answer = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Type MEETING to pause the timer for 1 hour.",
        "Pause Work Timer",
        ""
    )

    if ($answer -ceq "MEETING") {
		Pause-Timer
        Show-Balloon "Paused for 1 hour. Remaining time is frozen."
    } else {
        Show-Balloon "Pause cancelled."
    }
}

function Resume-Now {
	if ($(Resume-Timer)){
        Show-Balloon "Pause cleared."
    } else {
        Show-Balloon "No pause is active."
    }
}

function Show-TimeLeft {
    $state = Load-State
    Save-State $state

    $pause = Get-PauseData
    $msg = "Time left in this Session: $(Get-RemainingText $state.remainingSeconds)"

    if ($pause) {
        $until = [datetime]$pause.pauseUntil
        $msg += "`nPause active until: $($until.ToString('HH:mm'))"
    }

    if ($state.cooldownUntil) {
        $cool = [datetime]$state.cooldownUntil
        if ((Get-Now) -lt $cool) {
            $msg += "`nCooldown until: $($cool.ToString('HH:mm'))"
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
    Add-Content "$PSScriptRoot\debug.log" "Show-ExitChallenge returned: <$passed>"

    if (-not $passed) {
        Add-Content "$PSScriptRoot\debug.log" "Exit cancelled"
        return
    }

    $script:isExiting = $true

    if ($script:timer) {
        $script:timer.Stop()
    }

    if ($script:notifyIcon) {
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
    }

    [System.Windows.Forms.Application]::Exit()
}

# Tray icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = New-Object System.Drawing.Icon("$PSScriptRoot\time.ico")
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
$itemExit.Add_Click({ Exit-App })

$itemEmergency = $menu.Items.Add("Emergency unlock (15 min)")
$itemEmergency.Add_Click({ powershell.exe -ExecutionPolicy Bypass -File "C:\WorkTimer\emergency_unlock.ps1" })

$script:notifyIcon.ContextMenuStrip = $menu
$script:notifyIcon.Add_DoubleClick({ Show-TimeLeft })

# Timer loop
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = $tbfrelock

$script:timer.Add_Tick({
    $state = Load-State
	
	$properties = Load-Properties
	
	$firstWarning = $properties.workPeriod * 0.25
	if ($firstWarning -gt 30){$firstWarning = 30} else {$firstWarning = [Math]::Ceiling(%firstWarning/5)*5}
	$secondWarning = $properties.workPeriod * 0.125
	if ($secondWarning -gt 15) {$secondWarning = 15} else {$secondWarning = [Math]::Ceiling(%firstWarning/5)*5}
	if ($secondWarning -eq $firstWarning) $secondWarning = [Math]::Round($secondWarning)
	$thirdWarning = $properties.workPeriod * 0.0417
	if ($thirdWarning -gt 5) {$thirdWarning = 5} else {$thirdWarning = [Math]::Ceiling(%firstWarning/5)*5}
	if ($thirdWarning -eq $secondWarning) $thirdWarning = [Math]::Round($thirdWarning)

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
        Show-Message "$(Get-RemainingText $state.remainingSeconds $true) left. Save your work now and write next steps." "Work Timer"
        $state.warned5 = $true
    }

    if (-not $state.cooldown -and $state.remainingSeconds -le 0) {
        Show-Message "Time is up. The computer will lock now. Cooldown: $($properties.lockout) minutes." "Work Timer"
        $state.cooldownUntil = $now.AddMinutes($properties.lockOut).ToString("o")
		$state.cooldown = $true
        Lock-PC
    }

    $state.lastTick = $now.ToString("o")
    Save-State $state
})

$properties = Load-Properties

# Start
Ensure-State
Show-Balloon "Work Timer is running.`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime).`nWork for $(Get-RemainingText $properties.workPeriod $true). `nBreaks for $($properties.lockOut) minutes."
$script:timer.Start()

[System.Windows.Forms.Application]::Run()