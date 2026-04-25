function Get-Now {
    Get-Date
}

function Str-to-Date($dateStr){
	return [datetime]::Parse($dateStr)
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