# VMScript1

# Settings
$ServerName = 'ServerX'

# Rename the computer
Rename-Computer -NewName $ServerName

# Rename the existing (External) NIC
Get-NetAdapter | Rename-NetAdapter -NewName ExternalNIC

# Shutdown VM so a Host script can add the next NIC
Stop-Computer