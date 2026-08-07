Set WShell = CreateObject("WScript.Shell")
WShell.Run "pwsh.exe -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File ""C:\WorkTimer\scripts\work_timer.ps1""", 0, False