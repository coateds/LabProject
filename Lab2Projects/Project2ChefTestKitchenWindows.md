# Project 2: Chef Test Kitchen Windows
This will be building from work found <a href="https://github.com/coateds/DevOpsOnWindows/blob/master/HypervKitchen.md">here</a>
It is a continuation of Project 1: Host Configuration
The box is 'HyperHost1', a Windows 10 installation with the creator (Jul '17) newly installed

## An earlier lesson:  
A VM guest, when spun up by kitchen create, must be able to talk (network working) to the HyperV host running ChefDK or the process will time out and Kitchen will not be entirely aware of the guest. Make sure to call out a Virtual Switch that actually exists. (Configure default network switch "ExternalSwitch". Verify this switch is connected to the correct NIC. Can the guest connect to the network when done?)

## SW installed
* Windows 10
* Chocolatey (choco list --local-only)
  * Chocolatey v0.10.7
  * ChefDK 2.0.26
  * chocolatey 0.10.7
  * chocolatey-core.extension 1.3.1
  * DotNet4.5.2 4.5.2.20140902
  * git 2.13.3
  * git.install 2.13.3
  * poshgit 0.7.1
  * visualstudiocode 1.14.1

Of note: ChefDK 2.0.26 includes the Test Kitchen Hyper-V driver. This will be my first test of this.

## BaseBox Image
* An initial image was installed to test that HyperV was running. It has been updated with latest security updates. Attempt to export this to "BaseBox". I exported the VM to E:\HyperVResources\Guests\BaseBox and renamed the .vhdx file therein.

## Set up test-kitchen
* Create folder e:\chef and e:\chef\generator
* From within e:\chef\generator, chef generate generator hyperv_origin
* Create file e:\chef\config.rb with content  ---  *Does not work as expected!*
```
cookbook_path ['~/documents/cookbooks']
local_mode true
chefdk.generator_cookbook "C:/chef/generator/hyperv_origin"
```
* At this time call the generator from the chef generate command
* Edit E:\chef\generator\hyperv_origin\templates\default\kitchen.yml.erb to read:
```
---
driver:
  name: hyperv
  parent_vhd_folder: E:\HyperVResources\Guests\BaseBox
  parent_vhd_name: BaseBox.vhdx
  vm_switch: ExternalSwitch
  memory_startup_bytes: 2GB

provisioner:
  name: chef_zero

  transport:
  password: H0rnyBunny

verifier:
  name: pester

platforms:
  - name: windows-2012r2

suites:
  - name: default
    run_list:
      - recipe[<%= cookbook_name %>::default]
    verifier:
      inspec_tests:
        - test/smoke/default
    attributes:
```
* `chef generate cookbook ServerX1 -g e:\chef\generator\hyperv_origin`
* It does not like pester yet  --- STILL!!
  * `choco install pester`
  * `gem install pester`
* `kitchen list`  ---  to verify
* `kitchen create`  ---  see if it installs!

Base Image:  (not necessary for simple version)
* Get-NetFirewallPortFilter | ?{$_.LocalPort -eq 5985 } | Get-NetFirewallRule | ?{ $_.Direction –eq "Inbound" -and $_.Profile -eq "Public" -and $_.Action –eq "Allow"} | Set-NetFirewallRule -RemoteAddress "Any"
* winrm quickconfig

The simple version of this requires Gen 1

If Gen 2 add the following lines to the driver section"
```
  vm_generation: 2
  disable_secureboot: true
```

https://learn.chef.io/modules/local-development/windows/hyper-v/get-set-up#/

Kitchen Destroy seems to work in this version