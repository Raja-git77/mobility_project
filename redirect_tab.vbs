Set WshShell = CreateObject("WScript.Shell")
WshShell.SendKeys "%d"
WScript.Sleep 80
WshShell.SendKeys "http://127.0.0.1:8000{ENTER}"
