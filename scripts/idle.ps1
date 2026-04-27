# Define the P/Invoke structure and method
Add-Type @'
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static TimeSpan GetIdleTime() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
        
        if (GetLastInputInfo(ref lii)) {
            // Calculate idle time in milliseconds
            uint idleTicks = (uint)Environment.TickCount - lii.dwTime;
            return TimeSpan.FromMilliseconds(idleTicks);
        }
        return TimeSpan.Zero;
    }
}
'@ 


function Is-Idle($duration){
	$idle = [Win32]::GetIdleTime()
	if ($idle.TotalMinutes -ge $duration){
		return $true
	} else{
		return $false
	}
}
