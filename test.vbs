Set WShell = CreateObject("WScript.Shell")
WShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\WorkTimer\test.ps1""", 0, False