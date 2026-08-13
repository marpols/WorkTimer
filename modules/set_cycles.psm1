function set-cycles {

    Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
    
    $parentDir = Split-Path -Path $PSScriptRoot -Parent
    Import-Module "$parentDir/modules/properties.psm1"
    Import-Module "$parentDir/modules/hours_minutes.psm1"
    Import-Module "$parentDir/modules/controls.psm1"
    Import-Module "$parentDir/modules/toast.psm1"
    Import-Module "$parentDir/modules/play_chime.psm1"
    Import-Module "$parentDir/modules/utils.psm1"

    $propertiesPath = "$parentDir/json/properties.json"
	$properties = Load-Properties -propertiesPath $propertiesPath

    $formHeight = 320
    $startY = 270

    $cyclesform = New-Object System.Windows.Forms.Form -Property @{
		Text = "Set Number of Sessions";
		ClientSize = [System.Drawing.Size]::new(300, $formHeight);
		StartPosition = "CenterScreen";
		AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
		Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")
        ShowInTaskbar = $true
        TopMost       = $true
	}
    
    #cycles
    $numcycles = New-Object System.Windows.Forms.NumericUpDown -Property @{
        Location = [System.Drawing.Point]::new(80,15) 
        Size = [System.Drawing.Size]::new(50,50) 
        Minimum = 1 
        Maximum = 10 
        Value = $properties.cycles
        Increment = 1
        Font = [System.Drawing.Font]::new("Arial", 16, [System.Drawing.FontStyle]::Regular)
    }

    $labelcycles = New-Object System.Windows.Forms.Label -Property @{
        Text=if($numCycles.Value -eq 1){"Session"} else {"Sessions"}
        Location=[System.Drawing.Point]::new(140,20)
        Font = [System.Drawing.Font]::new("Arial", 14)
    }

    $numCycles.Tag = @{
        label = $labelcycles
    }
    $numcycles.Add_ValueChanged({
        param($sender, $e)

        $label = $sender.Tag.label

        $label.Text = if($sender.Value -eq 1){"Session"} else {"Sessions"}
    })


    $updateCycles = New-Object System.Windows.Forms.Button -Property @{
        Text = "Start"
        Location = [System.Drawing.Point]::new(120,$startY)
        Autosize = $true
        Font = [System.Drawing.Font]::new("Arial", 16, [System.Drawing.FontStyle]::Regular)
    }

    #set work period
    $curHours, $curMin = S-HM $properties.workPeriod

    $objHours = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '50,115'
		Size = '50,50'
		Maximum = 4
		Minimum = 0
		Value = $curHours
	}
	$objMin = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '160,115'
		Size = '50,50'
		Maximum = 59
		Minimum = 0
		Value = $curMin
	}

    $workControls = @($objHours, $objMin,
        (New-Object System.Windows.Forms.Label -Property @{Text = "Work period length:"; Location = '20,90'; Autosize=$true}),
	    (New-Object System.Windows.Forms.Label -Property @{Text = "Hours"; Location = '104,117'; Autosize=$true}),
	    (New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '214,117'; Autosize=$true})
    )

    # pomodoro toggle
    $checkboxPom = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Pomodoro"
		Location = [System.Drawing.Point]::new(20,65)
		Autosize=$true
		Checked = $properties.pomodoro
	}

    if (-not $checkboxPom.Checked){
        $formHeight -= 80
        $startY -= 80
    }

    $tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxPom, "If checked allows setting a short break time and longer break time seperately.")
	$cyclesform.Controls.Add($checkboxPom)

    #Set lockout period
    $objLO = New-Object System.Windows.Forms.NumericUpDown -Property @{
        Location = '100,150' 
        Size = '50,50' 
        Maximum = 60 
        Minimum = 0
        Value = $properties.lockOut
    }
	$titleLO = New-Object System.Windows.Forms.Label -Property @{
        Text = if($checkboxPom.Checked){"Long Break:"} else {"Break Length:"}
        Location = '20,152' 
        Autosize=$true
    }

    $lockoutControls = @($objLO, $titleLO,
    (New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '154,152'; Autosize=$true}))

    #Short break
	$objSB = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '100,190' 
		Size = '50,50' 
		Maximum = 60 
		Minimum = 0 
		Value = $properties.shortBreak
	}
	$titleSB = New-Object System.Windows.Forms.Label -Property @{
		Text = "Short break:" 
		Location = '20,192' 
		Autosize=$true
	}
	$labelSB = New-Object System.Windows.Forms.Label -Property @{
		Text = "Minutes" 
		Location = '154,192' 
		Autosize=$true
	}
    $shortBreakControls = @($objSB, $titleSB, $labelSB)
	
	#number of Pomodoros
	$pomNum = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '100,230' 
		Size = '50,50' 
		Maximum = 6 
		Minimum = 2 
		Value = $properties.numPomodoros
	}
	$pomTitle = New-Object System.Windows.Forms.Label -Property @{
		Text = "Pomodoros:" 
		Location = '20,232' 
		Autosize=$true
	}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($pomTitle,  "Enter the number of pomodoros (number of work periods before a long break)")

    $pomNumControls = @($pomNum, $pomTitle)

    $cyclesform.Controls.AddRange($workControls + $lockoutControls + $shortBreakControls + $pomNumControls)

    $checkboxPom.Tag = @{
        breakTitle = $titleLO
        shortbreak = $shortBreakControls
        pomNum = $pomNumControls
        form = $cyclesform
        start = $updateCycles
    }
    
    $checkboxPom.Add_CheckedChanged({
        param($sender, $e)

        $title = $sender.Tag.breakTitle 
        $shortBreak = $sender.Tag.shortBreak
        $pomNum = $sender.Tag.pomNum
        $form = $sender.Tag.form
        $start = $sender.Tag.start

        if($sender.checked){
            $title.Text = "Long Break:"
            $form.ClientSize = [System.Drawing.Size]::new(300,320)
            $start.Location = [System.Drawing.Point]::new(120,270)
        } else {
            $title.Text = "Break Length:"
            $form.ClientSize = [System.Drawing.Size]::new(300,240)
            $start.Location = [System.Drawing.Point]::new(120,190)
        }
        Set-ControlsVisible $sender.Checked ($shortBreak + $pomNum) 
    })

    $result = $null

    $updateCycles.Tag = @{
        Properties     = $properties
        PropertiesPath = $propertiesPath
        NumCycles      = $numcycles
        Form           = $cyclesform
        pomodoro = $checkboxPom
        hours = $objHours
        min = $objMin
        break = $objLO
        shortBreak = $objSB
        pomNum = $pomNumControls
    }

    $updateCycles.Add_Click({
        param($sender, $e)

        $properties = $sender.Tag.Properties
        $propertiesPath = $sender.Tag.PropertiesPath
        $curform = $sender.Tag.Form

        $numcycles = $sender.Tag.NumCycles.Value
        $hours = $sender.Tag.hours.Value
        $min = $sender.Tag.min.Value
        $pomodoro = $sender.Tag.pomodoro.Checked
        $break = $sender.Tag.break.Value
        $shortBreak = $sender.Tag.shortBreak.Value
        $pomNum = $sender.Tag.pomNum.Value

        $properties.cycles = $numcycles
        $time = HM-S $hours $min
        $properties.workPeriod = $time
        $properties.lockOut = $break
        $properties.pomodoro = $pomodoro
		if($pomodoro){
					$properties.shortBreak = $shortBreak
					$properties.numPomodoros = $pomNum
		}

        Save-Properties -propertiesPath $propertiesPath -properties $properties 

        $msg = if ($pomodoro) {"`nEach Set: $pomnum 🍅 Pomodoros`nWork For: $(Get-RemainingText $properties.workPeriod $true)`nShort Breaks: $shortBreak min  Long Break: $break min"}
            else {"Each Set:`n⏲️ Work For $(Get-RemainingText $properties.workPeriod $true)`nBreak: $break min"}

        Toast-Notification -msg "Work Timer will run for $($properties.cycles) sets(s)" + $msg

        $startCyclesEvent = [System.Threading.EventWaitHandle]::OpenExisting(
                "WorkTimerStartCycles"
        )
        
        $startCyclesEvent.Set() | Out-Null
        $startCyclesEvent.Dispose()

        $curform.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $curform.Close()
    })

    $cyclesControls = @($numcycles, $labelcycles, $updateCycles)
    $cyclesform.Controls.AddRange($cyclesControls)

        $dialogResult = $cyclesform.ShowDialog()

    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {

        return [int]$properties.cycles
    }



    return $null
}