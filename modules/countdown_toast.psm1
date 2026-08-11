function Countdown-Notification{
	    
		param(
		[int]$length = 5,
        [string]$msg = "",
		[string]$msg2 = "Get up and Stretch!",
		[string]$barTitle = 'Break Time Remaining: ',
		[string]$endMsg = 'Break time is over!',
        [string]$header = "Work Timer",
		[string]$endChime = "$parentDir\assets\sounds\alarm-bell.mp3",
		[bool]$chime = $true,
		[bool]$noPopup = $false,
		[int]$removeAfter = 60,
		[string]$imageFile = "$parentDir\assets\time.png"
		)

	
	$endTime =  $(Get-Date).AddMinutes($length)
	
	$DataBinding = @{
		'Title' = $barTitle
		'TimeLeft' = 0.0
		'Percent' = 0.0	
	}
	
	$headerText = New-BTHeader -Title $header
	$progressBar = New-BTProgressBar `
		-Title 'Title' `
		-Status 'TimeLeft' `
		-Value 'Percent'
	
	$ImagePath = New-BTImage -Source $imageFile -Crop None
	
	$Id = 'workTimerProgress'
	$expireAfter = $endTime.AddMinutes(5)

	$toastParameters = @{
        Header           = $headerText
        Text             = @($msg, $msg2)
        UniqueIdentifier = $Id
        AppLogo          = $ImagePath
        ProgressBar      = $progressBar
        DataBinding      = $DataBinding
        Sound            = "Default"
        Urgent           = $true
    }
	
   	if ($noPopup) {
        $toastParameters.SuppressPopup = $true
    }

	New-BurntToastNotification @toastParameters

	Progress-Bar `
		-DataBinding $DataBinding `
		-UniqueId $Id `
		-countdownTime $length `
		-msg $barTitle `
		-endMsg $endMsg `
		-endChime $endChime `
		-chime $chime
	
	Start-Sleep $removeAfter
	Remove-BTNotification -UniqueIdentifier $Id
}

function Progress-Bar{
	
	    param(
        [int]$countdownTime = 1,
		[string]$msg = 'Break Time Remaining: ',
		[string]$endMsg = 'Break time is over!',
        [hashtable]$DataBinding,
        [string]$UniqueId,
		[string]$endChime,
		[bool]$chime
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
		
		$DataBinding['Title'] = $msg
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
            $DataBinding['TimeLeft'] = $endMsg
        } 
		
		$null = Update-BTNotification -UniqueIdentifier $UniqueId -DataBinding $DataBinding
		

        Start-Sleep 0.5
    } Until ($now -ge $endTime)
	
	if($chime){
		Play-Chime -soundfile $endChime
	}
	
	return

}


function Start-Countdown{

	param(
		$duration,
		[bool]$chime = $true,
		[bool]$noPopup = $false,
		[string]$msg = "Break Time!",
		[string]$msg2 = "Get up and Stretch! Grab some food, have a drink.",
		[string]$barTitle = 'Break Time Remaining: ',
		[string]$endMsg = 'Break time is over!',
        [string]$header = "Work Timer",
		[string]$endChime = "$parentDir\assets\sounds\alarm-bell.mp3",
		[string]$imageFile = "$parentDir\assets\time.png",
		[int]$removeAfter = 60
	)

	$breakScript = @"
		param(
			`$duration,
			[int]`$chime,
			[int]`$noPopup,
			`$msg,
			`$msg2,
			`$barTitle,
			`$endMsg,
			`$header,
			`$endChime,
			`$imageFile,
			`$removeAfter
		)

		Import-Module "$parentDir/modules/toast_countdown.psm1" -Force
		Import-Module "$parentDir/modules/play_chime.psm1" -Force

		Countdown-Notification -length `$duration -chime ([bool]`$chime) -noPopup ([bool]`$noPopup) -msg `$msg -msg2 `$msg2 -barTitle `$barTitle -endMsg `$endMsg -header `$header -endChime `$endChime -imageFile `$imageFile -removeAfter `$removeAfter
"@

		$temp = Join-Path $env:TEMP "toast-$([guid]::NewGuid()).ps1"
		$breakScript | Set-Content -Path $temp -Encoding UTF8

		$psi = [System.Diagnostics.ProcessStartInfo]::new()
		$psi.FileName = (Get-Command pwsh).Source
		$psi.UseShellExecute = $false
		$psi.CreateNoWindow = $true
		$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

		$psi.ArgumentList.Add("-NoProfile")
		$psi.ArgumentList.Add("-ExecutionPolicy")
		$psi.ArgumentList.Add("Bypass")
		$psi.ArgumentList.Add("-File")
		$psi.ArgumentList.Add($temp)

		$psi.ArgumentList.Add("-duration")
		$psi.ArgumentList.Add($duration.ToString())

		$psi.ArgumentList.Add("-Chime")
		$psi.ArgumentList.Add(([int]$Chime).ToString())

		$psi.ArgumentList.Add("-NoPopup")
		$psi.ArgumentList.Add(([int]$NoPopup).ToString())

		$psi.ArgumentList.Add("-Msg")
		$psi.ArgumentList.Add($Msg)

		$psi.ArgumentList.Add("-Msg2")
		$psi.ArgumentList.Add($Msg2)

		$psi.ArgumentList.Add("-BarTitle")
		$psi.ArgumentList.Add($BarTitle)

		$psi.ArgumentList.Add("-endMsg")
		$psi.ArgumentList.Add($endMsg)

		$psi.ArgumentList.Add("-header")
		$psi.ArgumentList.Add($header)

		$psi.ArgumentList.Add("-endChime")
		$psi.ArgumentList.Add($endChime)

		$psi.ArgumentList.Add("-imageFile")
		$psi.ArgumentList.Add($imageFile)

		$psi.ArgumentList.Add("-removeAfter")
		$psi.ArgumentList.Add($removeAfter.ToString())


		[System.Diagnostics.Process]::Start($psi) | Out-Null
}