function Toast-Notification {
    
	param(
        [string]$msg = "",
        [string]$header = "Work Timer",
		[string]$soundfile = "$parentDir\assets\sounds\emergence.mp3",
		[bool]$chime = $true
    )

	$script = @"
	
		param(
			`$msg,
			`$header,
			`$soundfile,
			`$chime
		)
	
	Import-Module BurntToast
	Import-Module "$parentDir/modules/utils.psm1" -Function "Play-Chime" -Force
	
	
	`$Text1 = New-BTText -Content `$msg
	`$Header1 = New-BTText -Content `$header
	`$ImagePath = "C:\WorkTimer\assets\time.png"
	`$Image1 = New-BTImage -Source `$ImagePath -AppLogoOverride 
	`$Audio1 = New-BTAudio -Silent

	`$Binding1 = New-BTBinding -Children `$Header1, `$Text1 -AppLogoOverride `$Image1
	`$Visual1 = New-BTVisual -BindingGeneric `$Binding1
	`$Content1 = New-BTContent -Visual `$Visual1 -Audio `$Audio1 -Duration Long -Scenario Reminder

	Submit-BTNotification -Content `$Content1 -UniqueIdentifier "workTimerNotification"
	if (`$chime -eq 1){ Play-Chime `$soundfile }
	
	Start-Sleep 60
	Remove-BTNotification -UniqueIdentifier "workTimerNotification"
"@

	$temp = Join-Path $env:TEMP "toast-$([guid]::NewGuid()).ps1"
	$script | Set-Content -Path $temp -Encoding UTF8

	
	Start-Process pwsh `
		-WindowStyle Hidden `
		-ArgumentList @(
			'-NoProfile',
			'-ExecutionPolicy', 'Bypass',
			'-File', "`"$temp`"",
			"`"$msg`"",
			"`"$header`"",
			"`"$soundfile`"",
			"-chime", $(if ($chime) { "1" } else { "0" })
		)
		
}



