function workRem-options {
    param(
        $page,
        $properties,
        $sounds,
		$volume
    )

	Write-Host "PARAM volume null:" ($null -eq $volume)

    $workRemList = New-object System.Windows.Forms.ComboBox -Property @{
		DropDownStyle = "DropDownList";
		DropDownWidth = 150;
		Width = 150;
		Sorted = $false;
		Location = [System.Drawing.Point]::new(100,140);
		IntegralHeight = $false
	}
	$workRemTxt = New-Object System.Windows.Forms.Label -Property @{
    	Text = "Time left:";
    	Autosize=$true;
    	Location = [System.Drawing.Point]::new(20,140);
	}
	$workRemBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='Choose file';
		Location=[System.Drawing.Point]::new(100, 170);
		Autosize=$true
	}
	$workRemTxtBx = New-Object System.Windows.Forms.TextBox -Property @{
		Location = [System.Drawing.Point]::new(200, 175);
		Size = '240,20';
		ReadOnly = $true
	}

	$workRemList.DropDownHeight = ($workRemList.ItemHeight * 4) + 2
	$workRemList.Items.AddRange([object[]]$sounds.cleanName)

	$workRemChime = (
		[System.IO.Path]::GetFileNameWithoutExtension($properties.workEndChime)
	) -replace "-", " "

	$index = [array]::IndexOf(
		[object[]]$sounds.cleanName,
		$workRemChime
	)
	
	If ($sounds.cleanName -contains $workRemChime){
		$workRemList.SelectedIndex = $index
		$workRemTxtBx.Text = $workRemChime
	} else {
		$workRemList.SelectedIndex = 0
		$workRemTxtBx.Text = $properties.workEndChime
	}

	$workRemList.Tag = @{
		txtbox = $workRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}

	$workRemBtn.Tag = @{
		txtbox = $workRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}
	
	$workRemList.Add_SelectedIndexChanged({
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

		Play-Chime -soundFile $new_sound -volume ($volume.Value * 10)

		$txtbox.Text = $sounds.cleanName[$selectedIndex]
		$properties.workEndChime = $new_sound
	}
	)

	$workRemBtn.Add_Click({
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
			$properties.workEndChime = $FileDialog.FileName
		}
		 $fileDialog.Dispose()
	})

	$controls = (@($workRemList, $workRemBtn, $workRemTxt, $workRemTxtBx))
    $Page.Controls.AddRange($controls)

    return @{
        list = $workRemList 
        btn = $workRemBtn
        chime = $workRemChime 
        txt = $workRemTxt
        txtbox = $workRemTxtBx
		controls = $controls
    }
}