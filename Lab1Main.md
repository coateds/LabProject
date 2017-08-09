# Lab Project One
The computer on which lab one is located is connected with a job that probably has an expiration date. However, it has been so successful that starting a second lab on a permanent computer is justified.

Ongoing documentation and todo list for a first (temporary) HyperV lab including Windows, Ubuntu and DevOps servers/processes

## Refresh servers before Eval license expires (Aug 2017)
From the beginning, the purpose of this lab was to create an ability to crank out Server 2012R2 VMs based on an eval licensed iso. This way new servers can be built before the 180 day deadline and can take over roles such as domain controller and DNS server.

```diff
-The current batch of servers are based on an image that will expire on Aug 27, 2017.
```

Along the way, I hit on using Chef for much of the automation and this led me to working towards some Chef certifications.

My current procedure uses an odd combination of PowerShell scripts, ChefDK Test-Kitchen and integration with a Chef Server on an Ubuntu Server VM. I am using HyperV as my host mostly becuase I am most familiar with that particular technology. This is with the full knowledge that Chef on HyperV is problematic, however it is my understanding that there is a new partnership between Chef and Microsoft. It may just be that being a Chef expert for Windows may be a hot skill very soon. At this time, I am studying for the Local Chef Development badge, so I will be focusing more on the Test-Kitchen aspect of these processes, but I will work more with the Chef server to keep my skills there fresh.

The Chef, Test-Kitchen process uses a base image and differencing disk strategy for churning out test instances of VMs. As a consequence of using an eval iso for this, it is necessary to prepare a new BaseBox image every 180 days. All diff disk derived VMs from this image will have the save expiration date no matter how long after the image was created.

So my first task will be to create a new basebox image. This brings up an interesting philosophical question as it relates to studying Chef capabilities. There is a lot of (common) work that could go into building the BaseBox image, but the more that is done here, the less interesting work the Test-Kitchen and Chef Server processes could do later. One of the biggest issues is just how much to patch the BaseBox image.

Also, I am going to start using Gen2 VMs

```
Get-NetFirewallPortFilter | ?{$.LocalPort -eq 5985 } | Get-NetFirewallRule | ?{ $.Direction –eq "Inbound" -and $.Profile -eq "Public" -and $.Action –eq "Allow"} | Set-NetFirewallRule -RemoteAddress "Any"
winrm quickconfig
```

Proposed SW install list on BaseBox
```
Chocolatey
PowerShell 5.1
NuGet
(Trust PSGallary)
PSWindowsUpdate
Patches to Aug 2017
```

Patching
```
2017-08 rollup: KB4034681
```

Kitchen.yml
```
---
driver:
  name: hyperv
  parent_vhd_folder: D:\HyperVResources\VMs\BaseBox2\Virtual Hard Disks
  parent_vhd_name: BaseBox2.vhdx
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

BaseBox2 has some goofy shit going on move on to BaseBox3 Beware snapshotting a BaseBox??
* Settings
  * 1 proc, 2048
  * Location:  D:\HyperVResources\VMs
  * External NICs
  * DVD connected to Eval ISO
  * Gen 2
  * Disable Secure Boot in order to load from DVD



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
