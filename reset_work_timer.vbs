Set WShell = CreateObject("WScript.Shell")
WShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\WorkTimer\update_states.ps1""", 0, False