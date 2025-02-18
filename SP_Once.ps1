# admin check

param([switch]$Elevated)
function Check-Admin {
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
if ((Check-Admin) -eq $false)  {
if ($elevated)
{
# could not elevate, quit
}
 
else {
 
Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}
exit
}

# admin check end

########################################################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we need to force powershell to run in
#64-bit mode to allow the scripts to run properly.
########################################################################################################
#Write-Host $env:PROCESSOR_ARCHITECTURE
if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    write-warning "Re-launching in 64-bit mode...."
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

Write-Host $env:PROCESSOR_ARCHITECTURE

# go to usb
set-location (Get-WmiObject Win32_Volume -Filter 'DriveType=2' | Select-Object -first 1 | ForEach {$_.Name})

# copies the deploy folder to the SPAdmin desktop
Copy-Item deploy -Destination ([Environment]::GetFolderPath("Desktop")) -recurse

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