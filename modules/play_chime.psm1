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