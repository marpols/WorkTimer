function timeRem-Options {
    param(
        $page,
        $properties,
        $sounds,
		$volume
    )

    $timeRemList = New-object System.Windows.Forms.ComboBox -Property @{
		DropDownStyle = "DropDownList";
		DropDownWidth = 150;
		Width = 150;
		Sorted = $false;
		Location = [System.Drawing.Point]::new(100,70);
		IntegralHeight = $false
	}
	$timeRemTxt = New-Object System.Windows.Forms.Label -Property @{
    	Text = "Time left:";
    	Autosize=$true;
    	Location = [System.Drawing.Point]::new(20,70);
	}
	$timeRemBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='Choose file';
		Location=[System.Drawing.Point]::new(100, 100);
		Autosize=$true
	}
	$timeRemTxtBx = New-Object System.Windows.Forms.TextBox -Property @{
		Location = [System.Drawing.Point]::new(200, 105);
		Size = '240,20';
		ReadOnly = $true
	}

	$timeRemList.DropDownHeight = ($timeRemList.ItemHeight * 4) + 2
	$timeRemList.Items.AddRange([object[]]$sounds.cleanName)

	$timeRemChime = (
		[System.IO.Path]::GetFileNameWithoutExtension($properties.timeReminderChime)
	) -replace "-", " "

	$index = [array]::IndexOf(
		[object[]]$sounds.cleanName,
		$timeRemChime
	)
	
	If ($sounds.cleanName -contains $timeRemChime){
		$timeRemList.SelectedIndex = $index
		$timeRemTxtBx.Text = $timeRemChime
	} else {
		$timeRemList.SelectedIndex = 0
		$timeRemTxtBx.Text = $properties.timeReminderChime
	}

	$timeRemList.Tag = @{
		txtbox = $timeRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}

	$timeRemBtn.Tag = @{
		txtbox = $timeRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}
	
	$timeRemList.Add_SelectedIndexChanged({
		param($sender,$e)

		$selectedIndex = $sender.SelectedIndex
		$txtbox = $sender.Tag.txtbox
		$sounds = $sender.Tag.sounds
		$volume = $sender.Tag.vol
		$properties = $sender.Tag.properties


		if ($selectedIndex -lt 0) {
        return
		}
		
		$selectedSound = $sounds.Name[$selectedIndex]

		$new_sound = (Join-Path $parentDir "assets/sounds" $selectedSound)
		Play-Chime -soundFile $new_sound -volume $($volume.Value*10)
		$txtbox.Text = $sounds.cleanName[$selectedIndex]
		$properties.timeReminderChime = $new_sound
	}
	)

	$timeRemBtn.Add_Click({
		param($sender, $e)

		$txtbox = $sender.Tag.txtbox
		$volume = $sender.Tag.vol
		$properties = $sender.Tag.properties


		$FileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    	InitialDirectory = [Environment]::GetFolderPath('Desktop')
    	Filter           = 'Audio files (*.mp3;*.wav;*.wma;*.m4a)|*.mp3;*.wav;*.wma;*.m4a|MP3 files (*.mp3)|*.mp3|WAV files (*.wav)|*.wav|All files (*.*)|*.*'
    	Title            = 'Choose file'
		}

		if ($FileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

			$txtbox.Text = $FileDialog.FileName
			Play-Chime -soundFile $FileDialog.FileName -volume $($volume.Value*10)
			$properties.timeReminderChime = $FileDialog.FileName
		}
		 $fileDialog.Dispose()
	})

	$controls = (@($timeRemList, $timeRemBtn, $timeRemTxt, $timeRemTxtBx))
    $Page.Controls.AddRange($controls)

    return @{
        list = $timeRemList 
        btn = $timeRemBtn
        chime = $timeRemChime 
        txt = $timeRemTxt
        txtbox = $timeRemTxtBx
		controls = $controls
    }
}