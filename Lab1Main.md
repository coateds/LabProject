# Lab Project One
The computer on which lab one is located is connected with a job that probably has an expiration date. However, it has been so successful that starting a second lab on a permanent computer is justified.

Ongoing documentation and todo list for a first (temporary) HyperV lab including Windows, Ubuntu and DevOps servers/processes

## Refresh servers before Eval license expires (Aug 2017)
From the beginning, the purpose of this lab was to create an ability to crank out Server 2012R2 VMs based on an eval licensed iso. This way new servers can be built before the 180 day deadline and can take over roles such as domain controller and DNS server.

```diff
-The current batch of servers are based on an image that will expire on Aug 27, 2017.
```

Along the way, I hit on using Chef for much of the automation and this led me to working towards some Chef certifications.

My current procedure uses an odd combination of PowerShell scripts, ChefDK Test-Kitchen and integration with a Chef Server on an Ubuntu Server VM. I am using HyperV as my host mostly because I am most familiar with that particular technology. This is with the full knowledge that Chef on HyperV is problematic, however it is my understanding that there is a new partnership between Chef and Microsoft. It may just be that being a Chef expert for Windows may be a hot skill very soon. At this time, I am studying for the Local Chef Development badge, so I will be focusing more on the Test-Kitchen aspect of these processes, but I will work more with the Chef server to keep my skills there fresh.

The Chef, Test-Kitchen process uses a base image and differencing disk strategy for churning out test instances of VMs. As a consequence of using an eval iso for this, it is necessary to prepare a new BaseBox image every 180 days. All diff disk derived VMs from this image will have the save expiration date no matter how long after the image was created.

So my first task will be to create a new BaseBox image. This brings up an interesting philosophical question as it relates to studying Chef capabilities. There is a lot of (common) work that could go into building the BaseBox image, but the more that is done here, the less interesting work the Test-Kitchen and Chef Server processes could do later. One of the biggest issues is just how much to patch the BaseBox image.

Also, I am going to start using Gen2 VMs

### BaseBox Lessons
* The Test Kitchen instances all have the same SID
  * This does not seem to be a problem for most/all member servers
  * Domain Controllers should have a different SID than the member servers trying to join the domain
* Solution: Two BaseBox images
  * SysPrepped: D:\HyperVResources\VHDs\SysPreppedForNewSIDs
    * Create a new VM with bogus.vhdx for a disk
    * put a *copy* of the SysPrepped vhdx in the same location as bogus.vhdx and name it [ServerName].vhdx
    * edit VM to point at this relocated/renamed file (ACLs are adjusted at this time to grant access)
    * The new VM will have a reset 180 day clock
  * Not SysPrepped: D:\HyperVResources\VHDs\BaseBox3ForKitchen
    * ChefDK/Kitchen will use this
    * Every VM will have the same SID
    * Every VM will have the same expiration date
    * A new one of these will need to be generated from the sysprepped image every 180 days or less
    * Helpful to update patches when generating a new image
* Do not snapshot a BaseBox image

## Building the BaseBox VM
* Settings
  * 1 proc, 2048
  * Location:  D:\HyperVResources\VMs
  * External NIC
  * DVD connected to Eval ISO
  * Gen 2
  * Disable Secure Boot in order to load from DVD
* Proposed SW install list on BaseBox
  * Chocolatey
  * PowerShell 5.1
  * NuGet
  * (Trust PSGallary)
  * PSWindowsUpdate
  * Patches to Aug 2017
* Enable PSRemoting
* Enable RDP Connections





Kitchen.yml
```
---
driver:
  name: hyperv
  parent_vhd_folder: D:\HyperVResources\VHDs\BaseBox3ForKitchen
  parent_vhd_name: BaseBox3ForKitchen.vhdx
  vm_switch: ExternalSwitch
  memory_startup_bytes: 2GB
  vm_generation: 2
  disable_secureboot: true

provisioner:
  name: chef_zero

verifier:
  name: inspec

transport:
  password: H0rnyBunny

platforms:
  - name: windows-2012r2

suites:
  - name: default
    run_list:
      - recipe[ServerX2::default]
    verifier:
      inspec_tests:
        - test/smoke/default
    attributes:
```


## Using a generator
The first big difference between this round of rebuilds v the last will be the use of a generator. My convention lately has been to create a Chef directory at the root of the data drive (D: or E:) The following diagram shows an example structure

```
D:.
└───generator
    └───hypervlab_origin
        ├───files
        │   └───default
        │       ├───build_cookbook
        │       ├───cookbook_readmes
        │       └───repo
        │           ├───cookbooks
        │           │   └───example
        │           │       ├───attributes
        │           │       └───recipes
        │           ├───data_bags
        │           │   └───example
        │           ├───environments
        │           ├───policies
        │           └───roles
        ├───recipes
        └───templates
            └───default
                ├───build_cookbook
                └───repo
```

### templates/default/kitchen.yml.erb
The kitchen.yml template file is undoubtedly the place to start.

Section 1 - The driver section is typically unique to the Hypervisor type
```
driver:
  name: hyperv
  parent_vhd_folder: D:\HyperVResources\VMs\BaseBox3\Virtual Hard Disks
  parent_vhd_name: BaseBox3.vhdx
  vm_switch: ExternalSwitch
  memory_startup_bytes: 2GB
  vm_generation: 2
  disable_secureboot: true
```

Middle Sections
```
provisioner:
  name: chef_zero  # When using Test Kitchen, this line keeps everything local, there is no Chef server

verifier:
  name: inspec  # use this for now... Integration testing using Inspec
  -or-
  name: pester  # use this for PowerShell?? I have done some limited work with this

transport:
  password: <admin pw in clear text>

platforms:
  - name: windows-2012r2
```

Last Section
```
suites:
  - name: default
    run_list:
      - recipe[<%= cookbook_name %>::default]   # runs the default cookbook
    verifier:
      inspec_tests:
        - test/smoke/default
    attributes:
```

With the kitchen.yml done it is possible to generate the scaffolding for a test kitchen cookbook:
* chef generate cookbook ServerX4 -g D:\chef\generator\hypervlab_origin   # explicitly calls the generator
* chef\config.rb file
  * on scriptbox, one exists at c:\chef... I think this is the on that works and it must be located on the c: drive?

Kitchen Create pitfalls
* The Kitchen Process on the Host must be able to talk to the VM at the end of the process. This means networking between them must work.
* If using a Gen 2 BaseBox, the flag in the drivers section must be set to match

### Exercise: Put files in the generator structure that are then copied to generated cookbooks and finally copied to new servers

* Step 1: Add the following lines to:  chef\generator\hypervlab_origin\recipes\cookbook.rb
```
# Files
directory "#{cookbook_dir}/files"

cookbook_file "#{cookbook_dir}/files/script.ps1" do
  source 'script.ps1'
  action :create_if_missing
end
```
* Step 2: put a file, script.ps1, in chef\generator\hypervlab_origin\files\default
* Step 3: create a chefspec unit test
  * (chef exec rspec)
  * In chef\ServerX6\spec\unit\recipes\default_spec.rb
  ```
      it 'creates a file with the default action' do
        expect(chef_run).to create_file('C:\scripts\script.ps1')
      end
  -but really this should be moved to the generator default_spec file
  chef\generator\hypervlab_origin\templates\default\recipe_spec.rb.erb
  ```
* Step 4: write a recipe resource to satisfy the test (default.rb)
  * `file 'C:\scripts\script.ps1'`
  * in file D:\chef\generator\hypervlab_origin\templates\default\recipe.rb.erb
* Step 5: Add inspec tests to the generator template inspec_default_test.rb.erb
```
describe directory('C:\scripts') do
  it { should exist }
end

describe file('C:\scripts\script.ps1') do
  it { should exist }
end
```
* Run kitchen verify for inspec tests

## Integrating kitchen exec into the build process
My initial experiments with the `kitchen exec` command were highly successful. It suggests that a single script can be written to fully automate the base installation and common configurations of lab servers. For this iteration of the script, it will be stored on the main HyperV data drive at the root of the Chef directory (D:\Chef or E:\Chef etc) The intent is for this to be the initial working directory of the script.
```
# Settings
$NewComputerName = 'ServerX'
$NewComputerIP = '192.168.XXX.XXX'
$NewComputerDNS = '192.168.XXX.XXX,192.168.XXX.XXX'

# Use ChefDK tools to setup a cookbook for the new server.
# Some of the customizations for the servers will be included in the cookbook generator.
chef generate cookbook $NewComputerName -g D:\chef\generator\hypervlab_origin
Set-Location $NewComputerName
kitchen create

# Rename the VM and computer.
# The first command is run on the HyperV host and the second on the newly created guest using the kitchen exec command
Rename-VM -Name default-windows-2012r2 -NewName $NewComputerName
kitchen exec -c "Rename-Computer -NewName $NewComputerName"

# One of my self imposed requirements of the lab is to be able to run experiments among the servers on an internal only network.
# For instance, I am running my own tiny Windows AD domain and I do not want this to interfere with the corporate domains.
# During this installation process, the guest will use an externally connected NIC, but an internally connected NIC will be built as well.

# Rename the existing (External) NIC
# There is only one NIC at this point, naming it now will make it possible to distinguish it programmatically.
kitchen exec -c "Get-NetAdapter | Rename-NetAdapter -NewName ExternalNIC"

# Shutdown VM
# 1) So the new name of the Guest can take effect
# 2) So virtual hardware changes can be made to the VM. At this time add a new NIC
# The Get-VM | Stop command seems to block the script until the VM is shutdown
# which is exactly the desired behavior
Get-VM -Name $NewComputerName | Stop-VM
Add-VMNetworkAdapter -VMName $NewComputerName -SwitchName InternalSwitch

# Start the VM and converge it. This will run the recipe(s) in the cookbook
Get-VM -Name $NewComputerName | Start-VM
kitchen converge

# Rename and configure the new Internal NIC.
kitchen exec -c "Get-NetAdapter | Where-Object Name -ne 'ExternalNIC' | Rename-NetAdapter -NewName InternalNIC"
kitchen exec -c "Get-NetAdapter | Where-Object Name -eq 'InternalNIC' | New-NetIPAddress -PrefixLength 24 -IPAddress $NewComputerIP"
kitchen exec -c "Get-NetAdapter | Where-Object Name -eq 'InternalNIC' | Set-DnsClientServerAddress -ServerAddresses ('$NewComputerDNS')"

# Enable Remote Desktop
kitchen exec -c "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name 'fDenyTSConnections' -Value 0"

# Allow incoming RDP on firewall
kitchen exec -c "Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'"

# Enable secure RDP authentication
kitchen exec -c "Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name 'UserAuthentication' -Value 1"

# Call a script to join the domain
kitchen exec -c "Invoke-Expression c:\scripts\script.ps1"

```

c:\scripts\script.ps1
```
$PlainPassword = "H0rnyBunny"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$UserName = "CoateLab\Administrator"
$c = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

# Join Domain
Add-Computer -DomainName CoateLab -Credential $c
Restart-Computer
```

```diff
-The script to join the domain works, but there is not always an ability to find the domain controller in Lab1
```

# Patching
c:\scripts\InstallUpdates.ps1
```
Set-MyVmNetwork -Toggle ExternalOnly

If ((Get-WUInstall -ListOnly).Count -ne 0)
    {
    # There are updates available

    #Install, but do not reboot
    # Get-WUInstall –MicrosoftUpdate –AcceptAll –AutoReboot
    Get-WUInstall –MicrosoftUpdate –AcceptAll -IgnoreReboot

    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

    Set-MyVmNetwork -Toggle InternalOnly
    Restart-Computer
    }
Else
    {
    "No Updates Available"
    Set-MyVmNetwork -Toggle InternalOnly
    }
```

## Remove Servers 1 through 4 before Evaluation licenses expire
Top Priority is Server1
* Copy Modules
  * MyVmCommands
  * HtmlMonitor
  * StartupTools
* Create Folders
  * C:\Scripts\CSVs  --  copy and adjust contents
  * C:\Scripts\TempData
* Copy file c:\scripts\NewStartup.ps1
  * Register as Scheduled-Job
  * Instructions in the file comments
* Move FSMOs - see c:\scripts\ADScripts.ps1
* Copy c:\scripts\FixFirewallProfiles
* Demote Server1
* Adjust Client DNS with Chef
  * Default recipe in test_powershell
  * test_powershell:default.rb

Set-InternalDNS is included in Module MyVmCommands.psm1

    powershell_script 'set_dns' do
      code <<-EOH
      Set-InternalDNS '192.168.0.110'
      EOH
    end

## New Items to be added to build Hyper-V VM
To add chef-client:
Run at client during installation

  Get-NetFirewallPortFilter | ?{$_.LocalPort -eq 5985 } | Get-NetFirewallRule | ?{ $_.Direction –eq "Inbound" -and $_.Profile -eq "Public" -and $_.Action –eq "Allow"} | Set-NetFirewallRule -RemoteAddress "Any"

Run on ChefDK box. Server2 must be on. Run with no one logged on to client??

  knife bootstrap windows winrm 192.168.0.105 --winrm-user coatelab\administrator --winrm-password 'xxxxxxxxx' --node-name server5.coatelab.com --run-list 'recipe[learn_chef_iis]' --msi-url http://server2.coatelab.com/chef-client-12.18.31-1-x64.msi

  -or-

  knife bootstrap windows winrm 192.168.0.107 --winrm-user coatelab\administrator --winrm-password 'xxxxxxxxx' --node-name server7.coatelab.com --run-list 'role[web]' --msi-url http://server2.coatelab.com/chef-client-12.18.31-1-x64.msi

Does not install chef-client scheduled task. This should be added to the run-list in some way.
chef-client --once does not add the scheduled task.

Try from ChefDK  --  knife node run_list add server8.coatelab.com chef-client
Then chef-client on server8
That WORKED!!

The Web Role currently contains:
* 7.1.0  --  chef-client::default
* 7.1.0  --  chef-client::delete_validation
* 0.3.1  --  learn_chef_iis::default

Using --run-list 'role[web]', which includes the chef-client recipe, sets up the Sch Task.

## Current Customizations in lab (3/9/17)
In Server build recipe (Copy from D: drive on Script/Host box)
Files:
* MyVmCommands.psm1  (C:\Program Files\WindowsPowerShell\Modules\MyVmCommands)
* VMScript1.ps1  (C:\Scripts)
* VMScript2.ps1  (C:\Scripts)
Templates:
* server-info.txt.erb  (C:/temp)

-- Run Host and VM Scripts Here --
Networking, VMName, ServerName, AD membership, ChefClient

* chef-client::default (Sets up the Scheduled task etc)
* chef-client::delete_validation (deletes org PEM file)
* learn_chef_iis::default
  Source is Server4:  C:\Users\administrator.COATELAB\cookbooks\learn_chef_iis
  Installs IIS, configures to start, creates a default page from a template

## Modify learn_chef_iis to include a new .ps1 file
* once uploaded, this should find its way to multiple clients on scheduled task
* On Server 4...
* From C:\Users\administrator.COATELAB\cookbooks, chef generate file learn_chef_iis Scripts
* Rename File: C:\Users\administrator.COATELAB\cookbooks\learn_chef_iis\files\default\scripts to NewScript.ps1
* Add to default.rb file for the recipe:

  cookbook_file 'C:\Scripts\NewScript.ps1' do
      source 'NewScript1.ps1'
  end

* edit the cookbook metadata.rb to change the version number
* knife cookbook upload learn_chef_iis

## New Information - Chef virtualization
Vagrant/Virtual Box appear to be incompatible with HyperV already installed on the Lab box.

See:
https://learn.chef.io/local-development/windows/get-set-up/get-set-up-hyper-v/
https://learn.chef.io/local-development/windows/get-started-with-test-kitchen/

Install the Kitchen-HyperV driver per instructions

Notes from these two pages of tutorial
* chef gem install kitchen-hyperv
* (Install HyperV)
* Create Base Machine
  Store in D:\HyperVResources\VMs
    First Try of Base Box Server7
* Diff disk for Kitchen Created box:  D:\chef\settings_windows\.kitchen\default-windows-2012r2
  B8D48A56-45C3-4E89-B21D-6FD5A15B2981


    $vm = New-VM -Name BaseBox -MemoryStartupBytes 1GB -NewVHDPath "D:\HyperVResources\VMs\BaseBox\BaseBox.vhdx" -NewVHDSizeBytes 40GB -Path "D:\HyperVResources\VMs" -SwitchName ExternalSwitch
    $vm | Add-VMDvdDrive -Path "D:\HyperVResources\ISO\Server2012R2Eval.ISO"
    $vm | Set-VM -AutomaticStartAction StartIfRunning -AutomaticStopAction ShutDown
    $vm | Start-VM


Open Firewall for WinRM
Get-NetFirewallPortFilter | ?{$_.LocalPort -eq 5985 } | Get-NetFirewallRule | ?{ $_.Direction –eq "Inbound" -and $_.Profile -eq "Public" -and $_.Action –eq "Allow"} | Set-NetFirewallRule -RemoteAddress "Any"

Shutdown the BaseBox VM before building new servers on Diff Disks
Question: ----
  Can more than one box be built against the Diff disk?

## Build Cookbooks


chef generate cookbook [ServerName]
chef generate template [ServerName] server-info.txt
chef generate file [ServerName] Scripts

Copy File D:\chef\[ServerName]\templates\server-info.txt.erb
Copy File D:\chef\[ServerName]recipes\default.rb

.kitchen.yml

    ---
    driver:
      name: hyperv
      parent_vhd_folder: D:\HyperVResources\VMs\BaseBox
      parent_vhd_name: BaseBox.vhdx
      vm_switch: ExternalSwitch
      memory_startup_bytes: 2GB

    provisioner:
      name: chef_zero

    transport:
      password: H0rnyBunny

    platforms:
      - name: windows-2012r2

    suites:
      - name: default
          run_list:
          - recipe[Server7::default]
          attributes:

kitchen list to test
kitchen create  -- not needed, go straight to 'converge'

kitchen list to test
kitchen converge

## Steps
Will need to Rename the VM

## Chef Hyper-V driver
https://github.com/test-kitchen/kitchen-hyperv

## Another Resource
http://www.hurryupandwait.io/blog/help-test-the-future-of-windows-infrastructure-testing-on-test-kitchen

## Next Steps
* Rename the computer (VMScript1)
* Rename existing NIC to 'ExternalNIC' (VMScript1)
* Add another NIC and assign to internal switch.
  From the Host:  Add-VMNetworkAdapter -VMName Server7_2012R2 -SwitchName InternalSwitch
* Copy Scripts
  Modules\MyVmCommand


## ToDo list
Set up DNS alias for the location of the Chef Client msi
Document build new VM Process here (copy from OneNote)
* Migrate to PowerShell Script
* Refine/Document Chef Client install

setup Chef recipe/cookbook to
* install features roles iis, ad, dns
* copy script and module files


```
Get-NetFirewallPortFilter | ?{$.LocalPort -eq 5985 } | Get-NetFirewallRule | ?{ $.Direction –eq "Inbound" -and $.Profile -eq "Public" -and $.Action –eq "Allow"} | Set-NetFirewallRule -RemoteAddress "Any"
winrm quickconfig
```