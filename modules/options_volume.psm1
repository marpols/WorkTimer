function volume-options {
    param(
        $page,
        $properties
    )

    $volSlider = New-Object System.Windows.Forms.TrackBar -Property @{
		Location = [System.Drawing.Point]::new(275,40)
		Size = [System.Drawing.Size]::new(175,50)
		Minimum = 0
		Maximum = 100
		TickFrequency = 1
		LargeChange = 10
		SmallChange = 1
		}
	
		$volSlider.Value = [int]($properties.volume / 10)

	$volLabel = New-Object System.Windows.Forms.Label -Property @{
        Text='🔊'
        Location = [System.Drawing.Point]::new(250,40)
        Font = [System.Drawing.Font]::new("Segoe UI Emoji", 14)
    }

    $Page.Controls.AddRange(@($volSlider, $volLabel))

    $volSliderValue = [System.Windows.Forms.ToolTip]::new()

    $volSlider.Tag = @{
        ToolTip = $volSliderValue
    }

    $volSlider.add_Scroll({
        param($sender, $e)
		$val = $sender.Value
		$toolTip = $sender.Tag.ToolTip

		$range = $sender.Maximum - $sender.Minimum
		if ($range -eq 0) { $pct = 0 } else { $pct = ($sender.Value - $sender.Minimum) / $range }
    
		$usableWidth = $sender.Width - 30
		$newX = ($usableWidth * $pct) + 5

		$toolTip.Show(
			[string]"$val",
			$sender,
			$newX,
			-25,
			5000
		)
	})

	$volSlider.add_MouseUp({
        param($sender, $e)

		$toolTip = $sender.Tag.ToolTip

		play-Chime -volume $($sender.Value * 10)
		$toolTip.Hide($sender)
	})

    return @{
        volume = $volSlider
        label = $volLabel
        controls = @($volSlider, $volLabel)
    }

}