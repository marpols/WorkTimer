function pomodoro-Options {
    param(
            $Page,
            $Properties,
			$objLO
        )

    $checkboxPom = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Pomodoro"
		Location='30,10'
		Autosize=$true
		Checked = $properties.pomodoro
	}

	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxPom, "If checked allows setting a short break time and longer break time seperately.")
	$Page.Controls.Add($checkboxPom)

    #Short break
	$objSB = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '30,190' 
		Size = '50,50' 
		Maximum = 60 
		Minimum = 0 
		Value = $properties.shortBreak
	}
	$titleSB = New-Object System.Windows.Forms.Label -Property @{
		Text = "Short break length:" 
		Location = '10,170' 
		Autosize=$true
	}
	$labelSB = New-Object System.Windows.Forms.Label -Property @{
		Text = "Minutes" 
		Location = '84,195' 
		Autosize=$true
	}
	
	#number of Pomodoros
	$pomNum = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '30,240' 
		Size = '50,50' 
		Maximum = 6 
		Minimum = 2 
		Value = $properties.numPomodoros
	}
	$pomTitle = New-Object System.Windows.Forms.Label -Property @{
		Text = "Number of pomodoros:" 
		Location = '10,220' 
		Autosize=$true
	}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($pomTitle,  "Enter the number of pomodoros (number of work periods before a long break)")
	
	$updatePom = New-Object System.Windows.Forms.Button -Property @{
		Text = "Set pomodoro" 
		Location = '140,240' 
		Autosize=$true
	}
	$updatePom.Tag = @{
		checkbox = $checkboxPom
		lockout = $objLO
		shortBreak = $objSB
		pomNum = $pomNum
		properties = $properties
	}
	$updatePom.Add_Click({ 
		($sender, $e)

		$properties = $sender.Tag.properties
		$checkbox = $sender.Tag.checkbox
		$lockout = $sender.Tag.lockout
		$shortbreak = $sender.Tag.shortBreak
		$pomNum = $sender.Tag.pomNum

		$properties.pomodoro = $checkbox.Checked
		$properties.lockOut = $lockout.Value
		$properties.shortBreak = $shorBreak.Value
		$properties.numPomodoros = $pomNum.Value
		Save-Properties -properties $properties
		Toast-Notification `
			-msg "Pomodoro updated:`nShort Break: $($shorBreak.Value) minutes.`nLong Break: $($lockout.Value) minutes.`nNumber of Pomodoros: $($pomNum.Value)`nChanges will take effect on restart." `
			-header "Work Timer Update"
	})

    $titleLB = New-Object System.Windows.Forms.Label -Property @{
		Text = "Long break length:" 
		Location = '10,120' 
		Autosize=$true
	}

	$Page.Controls.AddRange(@($titleLB, $objSB, $titleSB, $labelSB, $pomNum, $pomTitle, $updatePom))

    return @{
        check = $checkboxPom
        shortBreak = $objSB
        sbTitle = $titleSB
        sbLabel = $labelSB
        pomNum = $pomNum
        numTitle = $pomTitle
        lbLabel = $titleLB
        btn = $updatePom
		controls = @($titleLB, $objSB, $titleSB, $labelSB, $pomNum, $pomTitle, $updatePom)
    }
}
