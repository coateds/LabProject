# HostScript2
$VMNname = 'Server7_2012R2'

# Stop VM - Not Needed if VMScript1 performs this action
# Get-VM -Name $VMNname | Stop-VM

# Add VM Network Adapter
Add-VMNetworkAdapter -VMName $VMNname -SwitchName InternalSwitch

# Start VM
Get-VM -Name $VMNname | Start-VM