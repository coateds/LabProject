<#
CreateNewServer.ps1

Generates a test kitchen instance framework of files and configures it through updates to the files

It appears that I run into problems if I try to run kitchen converge at the end of this script. Will run it manually for now.
#>

# Setup Server Instance Values
# Edit these lines before each run
$NewComputerName = 'Server16'
$NewComputerIP = '192.168.0.116'
$NewComputerDNS = '192.168.0.110,192.168.0.101'

# Setup paths and starting location
# The source files have been customized to the point simple subsitutions is all that is required
$ChefKitchenRoot = 'D:\Chef'
$SourceFiles = 'D:\chef\SourceFiles'
set-location $ChefKitchenRoot

# Use Chef Generate to create the framework with locations for both templates and files
chef generate cookbook $NewComputerName
chef generate template $NewComputerName server-info.txt 
###ToDo###
# This line generates an unwanted file
chef generate file $NewComputerName Scripts

# Copy Templates
Copy-Item -Path "$SourceFiles\templates\server-info.txt.erb" -Destination "$ChefKitchenRoot\$NewComputerName\templates"

# Edit and Copy Scripts
# vmscript1.ps1
# Substitute the new computer name
Copy-Item -Path "$SourceFiles\files\vmscript1.ps1" -Destination "$ChefKitchenRoot\$NewComputerName\files\default"
(Get-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript1.ps1").replace('[NewServer]', $NewComputerName) | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript1.ps1"

# vmscript2.ps1
# Substitute the new IP address and DNS Search Order
Copy-Item -Path "$SourceFiles\files\vmscript2.ps1" -Destination "$ChefKitchenRoot\$NewComputerName\files\default"
(Get-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript2.ps1").replace('[IPAddress]', $NewComputerIP) | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript2.ps1"
(Get-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript2.ps1").replace('[DNSSearchOrder]', $NewComputerDNS) | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\files\default\vmscript2.ps1"

# MyVMCommands.psm1
# A PowerShell module with custom tools
Copy-Item -Path "$SourceFiles\files\myvmcommands.psm1" -Destination "$ChefKitchenRoot\$NewComputerName\files\default"

# HostScript1.ps1
# Substitute the new VM name
Copy-Item -Path "$SourceFiles\files\HostScript1.ps1" -Destination "$ChefKitchenRoot\$NewComputerName"
(Get-Content "$ChefKitchenRoot\$NewComputerName\HostScript1.ps1").Replace('[NewVMName]', "$NewComputerName`_2012R2") | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\HostScript1.ps1"

# HostScript2.ps1
# Substitute the new VM name
Copy-Item -Path "$SourceFiles\files\HostScript2.ps1" -Destination "$ChefKitchenRoot\$NewComputerName"
(Get-Content "$ChefKitchenRoot\$NewComputerName\HostScript2.ps1").Replace('[NewVMName]', "$NewComputerName`_2012R2") | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\HostScript2.ps1"

# Kitchen Files (Kitchen.yml)
# Substitute the new computer name
Copy-Item -Path "$SourceFiles\KitchenRecipe\.kitchen.yml" -Destination "$ChefKitchenRoot\$NewComputerName"
(Get-Content "$ChefKitchenRoot\$NewComputerName\.kitchen.yml").Replace('[NewServer::default]', "[$NewComputerName::default]") | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\.kitchen.yml"

# Default recipe
# Substitute the new computer name
Copy-Item -Path "$SourceFiles\KitchenRecipe\default.rb" -Destination "$ChefKitchenRoot\$NewComputerName\recipes"
(Get-Content "$ChefKitchenRoot\$NewComputerName\recipes\default.rb").Replace('[Server]', $NewComputerName) | 
    Set-Content "$ChefKitchenRoot\$NewComputerName\recipes\default.rb"

# set-location "$ChefKitchenRoot\$NewComputerName"
# 
# kitchen converge