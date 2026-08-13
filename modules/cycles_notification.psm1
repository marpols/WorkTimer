function cycles-notification{
    param(
        [string]$msg = "",
        [string]$msg2 = "∘ Start with the current number`n∘ Set a new number`n∘ Or open properties to switch to Schedule Mode",
        [string]$header = "Work Timer is in Session Mode",
		[string]$soundfile = "$parentDir\assets\sounds\emergence.mp3",
		[bool]$chime = $true,
        [string]$button1_msg = "Start Work Timer",
        [string]$arg1 = "worktimer://start",
        [string]$button2_msg = "Change Number of Sets",
        [string]$arg2 = "worktimer://setcycles",
        [string]$button3_msg = "Exit Work Timer",
        [string]$arg3 = "worktimer://exit",
        [bool]$exit = $false,
        [string]$imageFile = "$parentDir\assets\time.png"
    )

    $Text1 = New-BTText -Content $msg
	$headerText = New-BTHeader -Title $header
	$ImagePath = New-BTImage -Source $imageFile -Crop None
	$Audio1 = New-BTAudio -Silent
    $Button1 = New-BTButton -Content $button1_msg -Arguments $arg1 -ActivationType Protocol
    $Button2 = New-BTButton -Content $button2_msg -Arguments $arg2  -ActivationType Protocol
    $Button3 = New-BTButton -Content $button2_msg -Arguments $arg2  -ActivationType Protocol
    $Id = 'workTimercyclesNotification'

    $buttons = $(if ($exit){ @($Button1,$Button2,$Button3)} else {@($Button1,$Button2)}) 

    $toastParameters = @{
        Header           = $headerText
        Text             = @($msg, $msg2)
        Button           = @($Button1,$Button2)
        UniqueIdentifier = $Id
        AppLogo          = $ImagePath
        Sound            = "Default"
        Urgent           = $true
    }

    if ($chime -eq 1){ Play-Chime $soundfile }
	New-BurntToastNotification @toastParameters
	


}