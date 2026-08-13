function toggle-schedule {
    param(
        $page,
        $properties
    )

	$scheduleMode = New-Object System.Windows.Forms.RadioButton -Property @{
        Text = "Schedule Mode"
        Location='80,30'
        Autosize=$true
    }
    $scheduleMode.Font = [System.Drawing.Font]::new(
        $scheduleMode.Font,
        [System.Drawing.FontStyle]::Bold
    )   

	$sessionMode = New-Object System.Windows.Forms.RadioButton -Property @{
        Text = "Session Mode"
        Location='80,100'
        Autosize=$true
    }
    $sessionMode.Font = [System.Drawing.Font]::new(
        $scheduleMode.Font,
        [System.Drawing.FontStyle]::Bold
    )  

    $scheduleMode.Checked = [bool]$properties.scheduled
    $sessionMode.Checked  = -not [bool]$properties.scheduled

    $schedInfo = New-Object System.Windows.Forms.Label -Property @{
        Text = "Runs automatically during your configured schedule" 
        Location = '95,55' 
        Autosize=$true
    }

    $seshInfo = New-Object System.Windows.Forms.Label -Property @{
        Text = "Runs for a specified number of sets" 
        Location = '95,125' 
        Autosize=$true
    }

    $numCycles = New-Object System.Windows.Forms.NumericUpDown -Property @{
        Location = '200,169'
        Size = '50,50' 
        Maximum = 10 
        Minimum = 1 
        Value = $properties.cycles
    }

    $cyclesLabel = New-Object System.Windows.Forms.Label -Property @{
        Text = "Number of sets:" 
        Location = '95,170' 
        Autosize=$true
    }

    $tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($cyclesLabel, "A set is one work/break cycle.`nIn Pomodoro mode, a set includes the configured number of Pomodoros and ends with the long break.")

    $modeControls = @($scheduleMode, $sessionMode, $schedInfo, $seshInfo, $numCycles, $cyclesLabel)
    $Page.Controls.AddRange($modeControls)

    Set-ControlsEnabled $sessionMode.Checked @($numCycles, $cyclesLabel)

    $sessionMode.Tag = @{
        controls = @($numCycles, $cyclesLabel)
    }

    $sessionMode.Add_CheckedChanged({
        param($sender, $e)
        Set-ControlsEnabled `
            $sender.Checked `
            $sender.Tag.controls
    })

    return @{
        schedule = $scheduleMode
        session = $sessionMode
        cycles   = $numCycles
    }

}