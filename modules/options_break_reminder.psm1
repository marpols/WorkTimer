function breakRem-options {
    param(
        $page,
        $properties,
        $sounds,
		$volume
    )

    $breakRemList = New-object System.Windows.Forms.ComboBox -Property @{
		DropDownStyle = "DropDownList";
		DropDownWidth = 150;
		Width = 150;
		Sorted = $false;
		Location = [System.Drawing.Point]::new(100,210);
		IntegralHeight = $false
	}
	$breakRemTxt = New-Object System.Windows.Forms.Label -Property @{
    	Text = "Time left:";
    	Autosize=$true;
    	Location = [System.Drawing.Point]::new(20,210);
	}
	$breakRemBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='Choose file';
		Location=[System.Drawing.Point]::new(100, 240);;
		Autosize=$true
	}
	$breakRemTxtBx = New-Object System.Windows.Forms.TextBox -Property @{
		Location = [System.Drawing.Point]::new(200, 245);;
		Size = '240,20';
		ReadOnly = $true
	}

	$breakRemList.DropDownHeight = ($breakRemList.ItemHeight * 4) + 2
	$breakRemList.Items.AddRange([object[]]$sounds.cleanName)

	$breakRemChime = (
		[System.IO.Path]::GetFileNameWithoutExtension($properties.breakEndChime)
	) -replace "-", " "

	$index = [array]::IndexOf(
		[object[]]$sounds.cleanName,
		$breakRemChime
	)
	
	If ($sounds.cleanName -contains $breakRemChime){
		$breakRemList.SelectedIndex = $index
		$breakRemTxtBx.Text = $breakRemChime
	} else {
		$breakRemList.SelectedIndex = 0
		$breakRemTxtBx.Text = $properties.breakEndChime
	}

	$breakRemList.Tag = @{
		txtbox = $breakRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}

	$breakRemBtn.Tag = @{
		txtbox = $breakRemTxtBx
		sounds = $sounds
		vol = $volume
		properties = $properties
	}
	
	$breakRemList.Add_SelectedIndexChanged({
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
		$properties.breakEndChime = $new_sound
	}
	)

	$breakRemBtn.Add_Click({
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
			$properties.breakEndChime = $FileDialog.FileName
		}
		 $fileDialog.Dispose()
	})

	$controls = (@($breakRemList, $breakRemBtn, $breakRemTxt, $breakRemTxtBx))
    $Page.Controls.AddRange($controls)

    return @{
        list = $breakRemList 
        btn = $breakRemBtn
        chime = $breakRemChime 
        txt = $breakRemTxt
        txtbox = $breakRemTxtBx
		controls = $controls
    }
}