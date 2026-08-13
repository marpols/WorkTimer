function work-Options {
    param(
            $Page,
            $Properties
        )

	$curHours, $curMin = S-HM $properties.workPeriod

    $objHours = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '30,60'
		Size = '50,50'
		Maximum = 4
		Minimum = 0
		Value = $curHours
	}
	$objMin = New-Object System.Windows.Forms.NumericUpDown -Property @{
		Location = '140,60'
		Size = '50,50'
		Maximum = 59
		Minimum = 0
		Value = $curMin
	}

	$updateWP = New-Object System.Windows.Forms.Button -Property @{
		Text = "Set work period"
		Location = '140,90'
		Autosize=$true
	}

	$updateWP.Tag = @{
		properties = $Properties
		hours = $objHours
		min = $objMin
	}

	$updateWP.Add_Click({
		param($sender, $e)

		$Properties = $sender.Tag.properties
		$hours = $sender.Tag.hours
		$min = $sender.Tag.min

		$time = HM-S $hours.Value $min.Value
		$properties.workPeriod = $time
		Save-Properties -properties $properties
		Toast-Notification `
			-msg "Work period duration updated to $($hours.Value) hour(s) and $($min.Value) minute(s).`nChanges will take effect on restart." `
			-header "Work Timer Update"
	})
	
	$Page.Controls.AddRange(@($objHours, $objMin, $updateWP,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Work period length:"; Location = '10,40'; Autosize=$true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Hours"; Location = '84,65'; Autosize=$true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '194,65'; Autosize=$true})))


    return $updateWP.Tag
}