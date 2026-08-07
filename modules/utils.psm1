if (-not ('NativeAudio' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class NativeAudio
{
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
    public static extern int mciSendString(
        string command,
        StringBuilder returnValue,
        int returnLength,
        IntPtr callback
    );
}
'@
}

function Get-Now {
    Get-Date
}

function Str-to-Date($dateStr){
	return [datetime]::Parse($dateStr)
}

function Is-Scheduled {
	$state = Load-State
    $day = (Get-Now).DayOfWeek
	
    return $day -in $state.days
}

function In-WorkHours {
	$state = Load-State
    $now = Get-Now
    $start = Str-to-Date($state.startTime)
    $end   = Str-to-Date($state.endTime)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function In-EveningLockWindow {
	$properties = Load-Properties
    $now = Get-Date
    $start = Str-to-Date($properties.endTime)
    $end   = $start.AddMinutes($properties.duration)
    return (Is-Scheduled) -and ($now -ge $start -and $now -lt $end)
}

function Lock-PC {
    rundll32.exe user32.dll,LockWorkStation
}

function Cleanup-TrayIcon {
    if ($script:notifyIcon) {
        $script:notifyIcon.Visible = $false
		if ($script:notifyIcon.ContextMenuStrip) {
            $script:notifyIcon.ContextMenuStrip.Dispose()
        }
        $script:notifyIcon.Dispose()
        $script:notifyIcon = $null
    }
}

function Get-RemainingText($seconds, $verbose = $false) {
    $seconds = [math]::Max(0, [int]$seconds)
    $ts = [TimeSpan]::FromSeconds($seconds)
	function is-plural($text){
		return $text + "s"
	}
    if ($ts.Hours -gt 0) {
		if($verbose){
			$text = "{0} hour" -f $ts.Hours
			if ($ts.Hours -ne 1){$text = is-plural $text}
			if($ts.Minutes -gt 0){
				$mintext = " {0} minute" -f $ts.Minutes
				if ($ts.Minutes -ne 1){$mintext = is-plural $mintext}
				$text += $mintext
			}
		} else {
			return = "{0}h {1}m" -f $ts.Hours $ts.Minutes
		}
    } else {
		if ($ts.Minutes -le 0) {
			if($verbose){
				$text = "{0} second" -f $ts.Seconds
				if ($ts.Seconds -ne 1){$text = is-plural $text}
				} else {
					return "{0}s" -f $seconds
				}
		} else {
			if($verbose){
				$text = "{0} minute" -f $ts.Minutes
				if ($ts.Minutes -ne 1){$text = is-plural $text}
			} else {
				return "{0}m" -f $ts.Minutes
			}
		}
	}
	return $text
}

function Play-Chime {
    param(
        [string]$SoundFile = "$parentDir/assets/sounds/emergence.mp3",
        [ValidateRange(0, 1000)]
        [int]$Volume = 500
    )

    if (-not (Test-Path -LiteralPath $SoundFile -PathType Leaf)) {
        Write-Warning "Sound file not found: $SoundFile"
        return
    }

    $fullPath = (Resolve-Path -LiteralPath $SoundFile).Path
    $alias = 'chimePreview'

    # Stop and release any previous preview
    [void][NativeAudio]::mciSendString(
        "close $alias",
        $null,
        0,
        [IntPtr]::Zero
    )

    $result = [NativeAudio]::mciSendString(
        "open `"$fullPath`" type mpegvideo alias $alias",
        $null,
        0,
        [IntPtr]::Zero
    )

    if ($result -ne 0) {
        Write-Warning "Unable to open sound file. MCI error: $result"
        return
    }

    [void][NativeAudio]::mciSendString(
        "setaudio $alias volume to $Volume",
        $null,
        0,
        [IntPtr]::Zero
    )

    [void][NativeAudio]::mciSendString(
        "play $alias",
        $null,
        0,
        [IntPtr]::Zero
    )
}

# function Play-Chime {
    
#     param(
#         [string]$SoundFile = "$parentDir/assets/sounds/long-chime-sound.mp3",
#         [double]$Volume = 1.0
#     )

#     if (-not (Test-Path -LiteralPath $SoundFile)) {
#         throw "Sound file not found: $SoundFile"
#     }

#     Add-Type -AssemblyName PresentationCore

#     if ($script:AudioPlayer) {
#         $script:AudioPlayer.Stop()
#         $script:AudioPlayer.Close()
#         $script:AudioPlayer = $null
#     }

#     $script:AudioPlayer = [System.Windows.Media.MediaPlayer]::new()s
#     $script:AudioPlayer.Volume = $Volume

#     $script:AudioPlayer.Add_MediaOpened({
#         $script:AudioPlayer.Play()
#     })

#     $script:AudioPlayer.Add_MediaEnded({
#         $script:AudioPlayer.Close()
#         $script:AudioPlayer = $null
#     })

#     $script:AudioPlayer.Add_MediaFailed({
#         param($sender, $eventArgs)

#         Add-Content "C:\WorkTimer\logs\debug.log" (
#             "$(Get-Date -Format o) Audio failed: " +
#             $eventArgs.ErrorException.Message
#         )

#         $script:AudioPlayer.Close()
#         $script:AudioPlayer = $null
#     })

#     $script:AudioPlayer.Open([uri]$SoundFile)
# }


