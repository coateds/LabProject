# LabProject
Ongoing documentation and todo list for a HyperV lab including Windows, Ubuntu and DevOps servers/processes

## Remove Servers 1 through 4 before Eval licenses expire

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

test_powershell:default.rb

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

* chef-client::default (Sets up the Sched task etc)
* chef-client::delete_validation (deletes org PEM file)
* learn_chef_iis::default
  Source is Server4:  C:\Users\administrator.COATELAB\cookbooks\learn_chef_iis
  Installs IIS, coinfigures to start, creates a default page from a template

## Modify learn_chef_iis to include a new .ps1 file
* once uploded, this should find its way to mutliple clients on sched task
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
