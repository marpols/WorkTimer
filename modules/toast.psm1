function Toast-Notification {
    
	param(
        [string]$msg = "",
        [string]$header = "Work Timer",
		[string]$soundfile = "$parentDir\assets\tiny-bell.mp3"
    )

	$script = @"
	
		param(
			`$msg,
			`$header,
			`$soundfile
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

	Submit-BTNotification -Content `$Content1
	Play-Chime `$soundfile
	
	Start-Sleep 60
	Remove-BTNotification
"@

	$temp = Join-Path $env:TEMP "toast.ps1"
	$script | Set-Content -Path $temp -Encoding UTF8
	
	Start-Process pwsh `
		-WindowStyle Hidden `
		-ArgumentList @(
			'-NoProfile',
			'-ExecutionPolicy', 'Bypass',
			'-File', "`"$temp`"",
			"`"$msg`"",
			"`"$header`"",
			"`"$soundfile`""
		)
		
}

function Break-Countdown{
	    
		param(
        [string]$msg = "",
		[string]$msg2 = "Get up and Stretch!",
        [string]$header = "Work Timer",
		$breakLength = 5,
		[string]$endChime,
		$chime = $true
		)

	
	$endTime =  $(Get-Date).AddMinutes($breakLength)
	
	$DataBinding = @{
		'Title' = ''
		'TimeLeft' = ''
		'Percent' = ''	
	}
	
	$headerText = New-BTHeader -Title $header
	$progressBar = New-BTProgressBar -Title 'Title' -Status 'TimeLeft' -Value 'Percent'
	
	$ImagePath = New-BTImage -Source "C:\WorkTimer\assets\time.png" -Crop None
	
	$Id = 'BreakProgress'
	$expireAfter = $endTime.AddMinutes(5)
	
	New-BurntToastNotification -Header $headerText -Text $msg, $msg2 -UniqueIdentifier $Id -AppLogo $ImagePath -ProgressBar $progressBar -DataBinding $DataBinding -Sound Default -Urgent

	Break-Progress -DataBinding $DataBinding -UniqueId $Id -countdownTime $breakLength -endChime $endChime -chime $chime
	
	Start-Sleep 60
	Remove-BTNotification -UniqueIdentifier $Id
}

function Break-Progress{
	
	    param(
        $countdownTime = 1,
        $DataBinding,
        $UniqueId,
		$endChime,
		$chime
    )
	
	Add-Type -AssemblyName presentationCore
	
	$startTime = Get-Date
    $endTime = $startTime.AddMinutes($countdownTime)
    $totalSeconds = (New-TimeSpan -Start $startTime -End $endTime).TotalSeconds
	
	Do {
        $now = Get-Date
        $secondsElapsed = (New-TimeSpan -Start $startTime -End $now).TotalSeconds
        $secondsRemaining = $totalSeconds - $secondsElapsed
        $percentDone = ($secondsElapsed / $totalSeconds)
		
		$DataBinding['Title'] = 'Break Time Remaining: '
        $DataBinding['Percent'] = $percentDone
		
		 if ($percentDone -le 1) {
			 $countDown = (New-TimeSpan -Start $(Get-Date) -End $endTime)
			 
			 if([Math]::Floor($countDown.Seconds/10) -eq 0){
				 $txt = "{0}:0{1}"
			 } else {
				 $txt = "{0}:{1}"
			 }
            $DataBinding['TimeLeft'] = $txt -f $countDown.Minutes, $countDown.Seconds
        } else {
            $DataBinding['TimeLeft'] = 'Break time is over!'
        } 
		
		$null = Update-BTNotification -UniqueIdentifier $UniqueId -DataBinding $DataBinding
		

        Start-Sleep 0.5
    } Until ($now -ge $endTime)
	
	if($chime){
		Play-Chime -soundfile $endChime
	}
	
	return

}

