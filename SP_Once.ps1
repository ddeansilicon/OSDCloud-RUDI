$RUDIDir = "C:\ProgramData\RUDI"
# go to usb
set-location "X:\"

# copies the deploy folder to the SPAdmin desktop
mkdir $RUDIDir
Copy-Item ".\deploy" -Destination $RUDIDir -recurse

$TargetFile = "C:\Users\SPAdmin\Desktop\deploy\SP_Restart.exe"
$ShortcutFile = "C:\Users\SPAdmin\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\SP_Install.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

#$bytes = [System.IO.File]::ReadAllBytes($ShortcutFile)
#$bytes[0x15] = $bytes[0x15] -bor 0x20
#[System.IO.File]::WriteAllBytes($ShortcutFile, $bytes)

Set-Location (([Environment]::GetFolderPath("Desktop")) + "\deploy")

./SP_Name.ps1
