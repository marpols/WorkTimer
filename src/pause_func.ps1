function Get-PauseData {
    if (-not (Test-Path $pausePath)) {
        return $null
    }

    try {
        $pause = Get-Content $pausePath -Raw | ConvertFrom-Json
        $until = [datetime]$pause.pauseUntil
        if ((Get-Now) -lt $until) {
            return $pause
        } else {
            Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
            return $null
        }
    } catch {
        Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
        return $null
    }
}

function Pause-Active {
    return $null -ne (Get-PauseData)
}

function Pause-Timer {
	$pause = @{
		pauseUntil = (Get-Date).AddHours(1).ToString("o")
	}
    $pause | ConvertTo-Json | Set-Content $pausePath -Encoding UTF8
}

function Resume-Timer {
    if (Test-Path $pausePath) {
        Remove-Item $pausePath -Force -ErrorAction SilentlyContinue
		return $true
	}
	return $false
}

function Pause-OneHour {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $answer = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Type MEETING to pause the timer for 1 hour.",
        "Pause Work Timer",
        ""
    )

    if ($answer -ceq "MEETING") {
		Pause-Timer
        Show-Balloon "Paused for 1 hour. Remaining time is frozen."
    } else {
        Show-Balloon "Pause cancelled."
    }
}

function Resume-Now {
	if ($(Resume-Timer)){
        Show-Balloon "Pause cleared."
    } else {
        Show-Balloon "No pause is active."
    }
}