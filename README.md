# LabProject
Ongoing documentation and todo list for a HyperV lab including Windows, Ubuntu and DevOps servers/processes

---

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
