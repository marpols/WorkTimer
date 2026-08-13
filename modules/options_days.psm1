function day-Options {
    param(
            $Page,
            $Properties
        )
    
    $daysList = New-Object System.Windows.Forms.CheckedListBox -Property @{
		Location='80,10' 
		Autosize=$true
		CheckOnClick = $true
	}
	$daysList.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

	for ($i = 0; $i -lt $daysList.Items.Count; $i++) {
		if($daysList.Items[$i].ToString() -in $properties.days){
			$daysList.SetItemChecked($i, $true)
		}
	}
	
	$weekDays = New-Object System.Windows.Forms.RadioButton -Property @{
		Text = "Weekdays Only" 
		Location='80,145'
		Autosize=$true
	}
	$weekEnds = New-Object System.Windows.Forms.RadioButton -Property @{
		Text = "Weekends Only"
		Location='80,165' 
		Autosize=$true
	}
	$allDays = New-Object System.Windows.Forms.RadioButton -Property @{
		Text = "Daily"
		Location='80,185' 
		Autosize=$true
	}

	$isWeekdays = (@(0..4) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
	$isWeekends = (@(5,6) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
	$isAll = (@(0..6) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
		
	if($isAll){
		$allDays.Checked = $true
	} elseif ($isWeekends){
		$weekEnds.Checked = $true
	} elseif ($isWeekdays) {
		$weekDays.Checked = $true
	}
	
	$updateDays = New-Object System.Windows.Forms.Button -Property @{
		Text="Set days of the week" 
		Location='80,210'
		Autosize=$true
	}

	#dynamic section

	$daysList.Tag = @{
    WeekDays = $weekDays
    WeekEnds = $weekEnds
    AllDays  = $allDays
	}

	$weekDays.Tag = @{
		DaysList = $daysList
	}

	$weekEnds.Tag = @{
		DaysList = $daysList
	}

	$allDays.Tag = @{
		DaysList = $daysList
	}

	$daysList.Add_ItemCheck({
		param($sender, $e)

		$controls = $sender.Tag

		$checkedAfterChange = @($sender.CheckedIndices)

		if ($e.NewValue -eq [System.Windows.Forms.CheckState]::Checked) {
			$checkedAfterChange += $e.Index
		} else {
			$checkedAfterChange = $checkedAfterChange | Where-Object { $_ -ne $e.Index }
		}

		$matchWeekdays =
			((@(0..4)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')
		$matchWeekends =
			((@(5,6)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')
		$matchAll =
			((@(0..6)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')

		if ($matchAll) {
			$controls.allDays.Checked = $true
		} elseif ($matchWeekends) {
			$controls.weekEnds.Checked = $true
		} elseif ($matchWeekdays){
			$controls.weekDays.Checked = $true
		} else {
			$controls.weekDays.Checked = $false
			$controls.weekEnds.Checked = $false
			$controls.allDays.Checked = $false
		}
	})

	$weekDays.Add_CheckedChanged({
		param($sender, $e)
		if ($sender.Checked){
			$daysList = $sender.Tag.DaysList
			0..4 | ForEach-Object {
				$daysList.SetItemChecked($_, $true)
			}	
			$daysList.SetItemChecked(5, $false)
			$daysList.SetItemChecked(6, $false)
		}
	}) 

	$weekEnds.Add_CheckedChanged({
		param($sender, $e)
		if ($sender.Checked){
			$daysList = $sender.Tag.DaysList
			0..4 | ForEach-Object {
				$daysList.SetItemChecked($_, $false)
			}
			$daysList.SetItemChecked(5, $true)
			$daysList.SetItemChecked(6, $true)
		}
	}) 

	$allDays.Add_CheckedChanged({
		param($sender, $e)
		if ($sender.Checked){
			$daysList = $sender.Tag.DaysList
			0..6 | ForEach-Object {
				$daysList.SetItemChecked($_, $true)
			}
		}
	})
	
	$updateDays.Tag = @{
		list = $daysList
		properties = $properties
	}

	$updateDays.Add_Click({ 
		param($sender, $e)

		$properties = $sender.Tag.properties
		$list = $sender.Tag.list

		$properties.days = @($list.CheckedItems | ForEach-Object { $_.ToString() })
		Save-Properties -properties $properties
		Toast-Notification `
			-msg "Work Timer will now be active on $($list.CheckedItems).`nChanges will take effect on restart." `
			-header "Work Timer Update"
	})

	$controlsSched = @($daysList, $updateDays, $weekDays, $weekEnds, $allDays)
	$Page.Controls.AddRange($controlsSched)

    return @{
        list = $daysList
        btn = $updateDays
        weekdays = $weekDays
        weekends = $weekEnds
        daily = $allDays
    }
}