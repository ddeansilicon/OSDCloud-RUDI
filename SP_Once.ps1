$configFilePath = "C:\ProgramData\RUDI\deploy\Config\config.json"
function Save-Config {
    param (
        [hashtable]$config
    )
    try {
        Write-Host -ForegroundColor Green "Disable Read-Only on config file"
        (Get-Item $configFilePath).IsReadOnly = $false
        $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configFilePath
        Write-Host -ForegroundColor Green "Config saved to $configFilePath"
        Write-Host -ForegroundColor Green "Set config file to Read-Only"
        (Get-Item $configFilePath).IsReadOnly = $true
    } catch {
        Write-Host -ForegroundColor Red "Error saving progress to ${configFilePath}: ${_}"
    }
}

function ConvertTo-Hashtable {
    param (
        [PSCustomObject]$object
    )
    $hashtable = @{}
    foreach ($property in $object.PSObject.Properties) {
        $hashtable[$property.Name] = $property.Value
    }
    return $hashtable
}

Write-Host -ForegroundColor Green "Starting OSDCloud ZTI"
Start-Sleep -Seconds 5

Start-OSDCloud -OSVersion 'Windows 11' -OSBuild 24H2 -OSEdition Pro -OSLanguage en-us -OSLicense Retail -ZTI

# go to usb
set-location "D:\"

# copies the deploy folder to the SPAdmin desktop
mkdir "C:\ProgramData\RUDI"
Copy-Item ".\deploy" -Destination "C:\ProgramData\RUDI" -recurse
#Copy-Item ".\deploy\Scripts\FirstLogon.ps1" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"

#Import Config File
Write-Host -ForegroundColor Green "Importing Config File to writeback PC Name"
if (-not (Test-Path $configFilePath)) {
    Write-Host -ForegroundColor Red "Configuration file not found. PC Rename will fail. Run wpeutil reboot to boot back into Windows. Exiting script. "
    exit 1
} else {
    #Import config file then convert to HashTable. That way it can be saved back to the JSON file later.
    $config = Get-Content $configFilePath | ConvertFrom-Json
    Write-Host -ForegroundColor Green "Config imported from $configFilePath"
    #Convert PSCustomObject to Hashtable
    $config = ConvertTo-HashTable -object $config
}

#Grab PC Name from user input
$config.PCName = Read-Host -prompt 'Please enter the PC Name'
#Save config edits back to the config file
Save-Config -config $config

#Creates a new shortcut to the TestScript.ps1 and places shortcut in the all users startup folder
$TargetFile = "powershell.exe"
$ShortcutFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\TestScript.lnk"
$Shortcutargs = "-ExecutionPolicy RemoteSigned -file C:\ProgramData\RUDI\deploy\Scripts\TestScript.ps1"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = $Shortcutargs
$Shortcut.Save()

#Disable UAC by importing the reg hive from the newly imaged PC
Write-Host -ForegroundColor Green "Disabling UAC..."
reg load HKLM\TempSoftware "C:\Windows\System32\config\software"
Set-ItemProperty -Path HKLM:\TempSoftware\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -Value 0
reg unload HKLM\TempSoftware

#Restart from WinPE

Write-Host -ForegroundColor Green “Restarting in 60 seconds!”

Start-Sleep -Seconds 60

wpeutil reboot
