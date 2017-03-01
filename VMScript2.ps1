# Settings
$IP = '192.168.0.XXX'

# Rename new Internal NIC.
Get-NetAdapter | Where-Object Name -ne 'ExternalNIC' | Rename-NetAdapter -NewName InternalNIC

# Set InternalNIC static IP address
Get-NetAdapter | Where-Object Name -eq 'InternalNIC' | New-NetIPAddress -PrefixLength 24 -IPAddress $IP

# Set DNS on InternalNIC
Get-NetAdapter | Where-Object Name -eq 'InternalNIC' | Set-DnsClientServerAddress -ServerAddresses ('192.168.0.101')

# Disable External NIC
Disable-NetAdapter -Name ExternalNIC -Confirm:$false
# OR
Set-MyVmNetwork -Toggle InternalOnly

# Is RDP Enabled??
# Enable Remote Desktop
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0

# Allow incoming RDP on firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Enable secure RDP authentication
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   

$PlainPassword = "H0rnyBunny"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$UserName = "CoateLab\Administrator"
$c = New-Object System.Management.Automation.PSCredential `
     -ArgumentList $UserName, $SecurePassword 

# Join Domain
Add-Computer -DomainName CoateLab -Credential $c
Restart-Computer