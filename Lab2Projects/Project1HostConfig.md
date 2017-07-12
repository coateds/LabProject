# Project 1: Host Configuration
register the Win 10 license account.microsoft.com/devices

This Windows 10 computer already has WMF/PowerShell v5.1 installed.
* `Install-PackageProvider -Name "NuGet" -force`
* `Set-PSRepository -Name PSGallery -InstallationPolicy Trusted`
* `Install-Module -Name PSWindowsUpdate`
* `Set-ExecutionPolicy RemoteSigned`
* `Add-WUServiceManager -ServiceID [GUID]`
* `Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot`

Rename the Computer
* `Rename-Computer -NewName HYPERHOST1 -force`

PS Modules - Get-Module -ListAvailable -name pester  ---  installed

Look at the ChocolateyGet Module  ---  I still do not know what this gains me
* `Find-Module ChocolateyGet | Install-Module`

Install Chocolatey  ---  `iex...`
* `Get-PackageProvider -Name chocolatey -force`  --- This ***May*** eliminate the need for the `iex...` command??
* `Set-PackageSource -Name chocolatey -Trusted`

Install Git
* `choco install git -y -params '/GitAndUnixToolsOnPath'`
* `RefreshEnv`

Install VSCode
* `choco install visualstudiocode -y`

Install Posh-Git
`choco install poshgit -y`



Install Software
* Chocolatey
* Latest PowerShell
* Git
* Posh-Git
* VSCode
  *Extensions and customizations
* HyperV
  * Virtual Network
  * Connect host to internal network
* ChefDK
* RDCMan
  * `choco install rdcman`
  * `Install-Package rdcman`  results in ambiguity error
    * Available on Chocolatey and PSGallery
    * Specify -ProviderName!!
    * ex: `Install-Package rdcman -ProviderName PowerShellGet`  - did not work
    * ex2: `Install-Package rdcman -ProviderName Chocolatey`   - worked
