function ELO-Options {
    param(
            $Page,
            $Properties
        )

    $checkboxELO = New-Object System.Windows.Forms.Checkbox -Property @{Text = "Enable evening lockout"; Location='290,10'; Autosize=$true; Checked = $properties.eveningLO}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxELO, "Schedule Mode: Set a longer lockout period for the end of your workday.")
	
	$labelELO = New-Object System.Windows.Forms.Label -Property @{Text="Duration:"; Location='290,40'; Autosize=$true}
	$objELO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location='310,60'; Size='50,50'; Minimum=20; Maximum=60; Value=$properties.duration}
	$labelELO2 = New-Object System.Windows.Forms.Label -Property @{Text="Minutes"; Location='364,65'; Autosize=$true}
	$updateELO = New-Object System.Windows.Forms.Button -Property @{Text="Update"; Location='290,90';Autosize=$true}

    $Page.Controls.AddRange(@($objELO, $labelELO, $labelELO2, $checkboxELO, $updateELO))

	$updateELO.Tag = @{
    	Properties = $Properties
    	Checkbox   = $checkboxELO
    	Duration   = $objELO
	}

	$updateELO.Add_Click({
		param($sender, $e)

		$properties = $sender.Tag.Properties
    	$checkbox   = $sender.Tag.Checkbox
    	$duration   = $sender.Tag.Duration

		$properties.eveningLO = $checkbox.Checked
		$properties.duration = $duration.Value
		Save-Properties -properties $properties
		if($checkbox.Checked){
			$msg = "Evening Lockout Enabled for $($Duration.Value) minutes.`nChanges will take effect after restarting Work Timer."
		} else{
			$msg = "Evening Lockout Disabled.`nChanges will take effect on restart."
		}
		Toast-Notification -msg $msg -header "Work Timer Update"
	})

	$ELOcontrols = @($objELO, $labelELO, $labelELO2)
	$allELOControls = @($checkboxELO, $labelELO, $objELO, $labelELO2, $updateELO) 

	$checkboxELO.Tag = @{
		controls = $ELOcontrols
	}

	Set-ControlsEnabled $properties.scheduled $allELOControls
	Set-ControlsEnabled $checkboxELO.Checked $ELOcontrols

	$checkboxELO.Add_CheckedChanged({
		param($sender, $e)
		
		Set-ControlsEnabled $sender.Checked $sender.Tag.controls
	})
	
	return @{
        check = $checkboxELO
        label = $labelELO
        value = $objELO
        label2 = $labelELO2
        btn = $updateELO
		controls = $ELOcontrols
		all_controls = $allELOControls
    }
}