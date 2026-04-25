Set WShell = CreateObject("WScript.Shell")
WShell.Run "pwsh.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\WorkTimer\src\work_timer.ps1""", 0, False