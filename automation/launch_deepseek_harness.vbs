' ==============================================================================
' DeepSeek Harness Silent Launcher (Zero Console Window Popup)
' Part of: DeepSeek Harness Local LLM Suite
' ==============================================================================
Set objFSO = CreateObject("Scripting.FileSystemObject")
strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strPS1 = objFSO.BuildPath(strScriptDir, "launch_deepseek_harness.ps1")

Set objShell = CreateObject("WScript.Shell")
strCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPS1 & """"
objShell.Run strCommand, 0, False
