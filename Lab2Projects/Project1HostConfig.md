# Project 1: Host Configuration
register the Win 10 license account.microsoft.com/devices

Rename the Computer
* `Rename-Computer -NewName HYPERHOST1 -force`

## Install Software

This Windows 10 computer already has WMF/PowerShell v5.1 installed.
* `Install-PackageProvider -Name "NuGet" -force`
* `Set-PSRepository -Name PSGallery -InstallationPolicy Trusted`
* `Install-Module -Name PSWindowsUpdate`
* `Set-ExecutionPolicy RemoteSigned`
* `Add-WUServiceManager -ServiceID [GUID]`
* `Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot`

PS Modules - Get-Module -ListAvailable -name pester  ---  installed

Look at the ChocolateyGet Module  ---  I still do not know what this gains me
* `Find-Module ChocolateyGet | Install-Module`

Install Chocolatey  ---  `iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
* `Get-PackageProvider -Name chocolatey -force`
* `Set-PackageSource -Name chocolatey -Trusted`

Install Git
* `choco install git -y -params '/GitAndUnixToolsOnPath'`
* `RefreshEnv`

Install VSCode 
* `choco install visualstudiocode -y`

Install Posh-Git
* `choco install poshgit -y`

VSCode PS Extension
* `Install-Package vscode-powershell`

Other VSCode extensions and customizations
* Git History and Code Spellchecker (via VSCode GUI)
* Set up gitignore for .vscode directory (global)
* Set custom keyboard shortcuts Shift+Alt+Up/Down

Install HyperV via GUI
* PS: (`Enable-WindowsOptionalFeature -Online -FeatureName:Microsoft-Hyper-V -All`)
* Configuration yet to be done
  * Virtual switches
  * Connect VMs
  * Connect host to internal network

VM Switches and Net Adapters
* `Get-NetAdapter`
* `Get-VMSwitch`
* `New-VMSwitch -Name ExternalSwitch -NetAdapterName "Ethernet 2" -AllowManagementOS $true`
* `New-VMSwitch -Name InternalSwitch -SwitchType Internal `

Set Host VMNet Adapters
* External to DHCP client... gets 169... address. Come back to this sometime?
  * When running HyperV on a host, the external virtual NIC "takes over" the wired physical NIC
  * Ipconfig only shows the External vEthernet
  * GUI shows both, but the physical NIC is not configured for IPv4.
* Internal to 192.168.5.100

`choco install ChefDK -y`
`Install-Package rdcman -ProviderName Chocolatey`

Install some features this way
* `choco install [feature] -source WindowsFeatures`

## Hyper-V Configuration
* Start by changing the locations of Hyper-V guest files
* Hyper-V Settings
  * Virtual Hard Disk Location:  E:\HyperVResources\Guests
* Goal is to store all virtual hard disks on the E: drive, specifically:  E:\HyperVResources\Guests