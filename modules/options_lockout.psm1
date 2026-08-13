function lockout-Options {
    param(
            $Page,
            $Properties
        )

    $objLO = New-Object System.Windows.Forms.NumericUpDown -Property @{
        Location = '30,140' 
        Size = '50,50' 
        Maximum = 60 
        Minimum = 0
        Value = $properties.lockOut
    }
	$titleLO = New-Object System.Windows.Forms.Label -Property @{
        Text = "Break length:"
        Location = '10,120' 
        Autosize=$true
    }
	$updateLO = New-Object System.Windows.Forms.Button -Property @{
        Text = "Set Break" 
        Location = '140,140' 
        Autosize=$true
    }

    $updateLO.Tag = @{
        properties = $Properties
        lockout = $objLO
    }

	$updateLO.Add_Click({ 
        param($sender, $e)
        $properties = $sender.Tag.properties
        $lockout = $sender.Tag.lockout

		$properties.pomodoro = $false
		$properties.lockOut = $lockout.Value
		Save-Properties -properties $properties
		Toast-Notification -msg "Lockout duration updated to $($lockout.Value) minutes.`nChanges will take effect on restart." -header "Work Timer Update"
	})

    $Page.Controls.AddRange(@($objLO, $titleLO, $updateLO,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '84,145'; Autosize=$true})))
    
    return @{
        value = $objLO
        label = $titleLO
        btn = $updateLO  
        controls = @($titleLO, $updateLO)
    }
}