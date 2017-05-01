# Somtimes the firewall profile on these boxes get messed up
# As a result, servers are not always available via RDP after reboot
# This code block fixes that
# This code block is currently included in a reboot script on Server10
# From Server10, the other servers can get fixed via PS Remote

$sb = {
Set-NetFirewallProfile -profile public,private -Enabled false
Disable-NetAdapter -Name InternalNIC -Confirm:$false
Enable-NetAdapter -Name InternalNIC -Confirm:$false
Set-NetFirewallProfile -profile public,private -Enabled true}

# Invoke-command -ComputerName ("Server2") -ScriptBlock $sb
# Invoke-command -ComputerName ("Server1","Server2","Server3","Server4","Server5") -ScriptBlock $sb
