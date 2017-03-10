<#
.Synopsis
   Toggles Internal/External NICs

.EXAMPLE
   Set-MyVmNetwork -Toggle InternalOnly

.EXAMPLE
   Set-MyVmNetwork -Toggle ExternalOnly
#>
Function Set-MyVmNetwork
{
    [CmdletBinding()]
    
    Param
        (
        # Param1 help description
        [Parameter(Mandatory=$true)]
        [ValidateSet("InternalOnly", "ExternalOnly")]
        $Toggle,

        [switch]
        $Quiet
        )

    switch ($Toggle)
        {
        'InternalOnly' 
            {
            Enable-NetAdapter -Name InternalNIC -Confirm:$false 
            Disable-NetAdapter -Name ExternalNIC -Confirm:$false
            # $FWStatus = Set-NetFirewallProfile -Enabled False -Name Public -PassThru
            }
        'ExternalOnly' 
            {
            # $FWStatus = Set-NetFirewallProfile -Enabled True -Name Public -PassThru
            Enable-NetAdapter -Name ExternalNIC -Confirm:$false
            Disable-NetAdapter -Name InternalNIC -Confirm:$false
            }
        }

    # "Public Firewall " + ($FWStatus).Enabled
    If ($Quiet -eq $false)  {Get-NetAdapter | select name, status}
    
}

