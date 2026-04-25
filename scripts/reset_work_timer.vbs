Set WShell = CreateObject("WScript.Shell")
WShell.Run "pwsh.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\WorkTimer\src\update_states.ps1""", 0, False