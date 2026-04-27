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
	$balloon = New-Object System.Windows.Forms.NotifyIcon
	$path = (Get-Process -Id $pid).Path
	$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
	$balloon.BalloonTipTitle = $title
	$balloon.BalloonTipText = $text
	$balloon.Visible = $true
	$balloon.ShowBalloonTip($timeout)
	$balloon.Dispose()
}

function Show-Popup {
	param(
		[string]$text,
		[string]$title = "Work Timer",
		[int]$timeout = 3000,
		$chime = $true,
		[string]$soundfile = "$parentDir\assets\chimes-glassy-456.mp3",
		$volume = 1.0
		)

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName presentationCore

	$icon = New-Object System.Drawing.Icon("C:\WorkTimer\assets\time.ico")
	$form = New-Object System.Windows.Forms.Form -Property @{Text = $title; Size = '300,150'; StartPosition = "CenterScreen"; TopMost = $true; Icon = $icon}
	$label = New-Object System.Windows.Forms.Label -Property @{Text = $text; Dock = "Fill"; TextAlign = "MiddleCenter"}

	$form.Controls.Add($label)

	$timer = New-Object System.Windows.Forms.Timer
	$timer.Interval = $timeout
	$timer.Add_Tick({
		$timer.Stop()
		$form.Close()
	}.GetNewClosure())

	$form.Add_Shown({
		$timer.Start()
	}.GetNewClosure())
	
	$mediaPlayer = New-Object system.windows.media.mediaplayer -Property @{Volume = $volume}
	$mediaPlayer.open($soundfile)
	
	if($chime){
		$mediaPlayer.Play()
	}
	[void]$form.ShowDialog()
	

    $timer.Dispose()
    $form.Dispose()
    $icon.Dispose()
}

function Lock-PC {
    rundll32.exe user32.dll,LockWorkStation
}

function Cleanup-TrayIcon {
    if ($script:notifyIcon) {
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
        $script:notifyIcon = $null
    }
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

function Pom-Message ($state){
	Show-Balloon "🍅 Pomodoro:  $($state.numPomodoros - $state.pomNum + 1) out of $($state.numPomodoros)" "Work Timer is Active"
}

function Timer-Message ($state){
	Show-Balloon "⏲️ Work Time: $(Get-RemainingText $state.workPeriod $true)`n Breaks: $(Get-RemainingText $state.lockOut*60 $true)" "Work Timer is Active"
}