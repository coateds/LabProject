# PowerShell Startup Scripts
Use a ScheduledJob to call a Function in a Module.

This can imitate a service if the ScheduleJob is set to start at boot up.

## Technical setup
Create a PowerShell script file (C:\Scripts\NewStartup.ps1)


    <#
    Get-ScheduledJob | Unregister-ScheduledJob -force
    Register-ScheduledJob -Name StartupJob -FilePath C:\Scripts\NewStartup.ps1 -Credential (Get-Credential coatelab\administrator) -MaxResultCount 30 -ScheduledJobOption (New-ScheduledJobOption -DoNotAllowDemandStart) -Trigger (New-JobTrigger -AtStartup)
    #>

    Start-AtBootFunction

This file cannot change without having to unregister and register. These are the 2 commands within the <#..#> block.
Run just the second command to set up the job in the first place, run both commands when changing the job for any reason.
Oddly enough this script is very limited in what it can do. The most flexible strategy seems to be calling just a single function from a module.

Build a Module:
C:\Program Files\WindowsPowerShell\Modules\StartupTools\StartupTools.psm1
In it build a Function: Start-AtBootFunction.
It is possible to make changes to this function and have the new script take effect with only a reboot.
This function can also have an infinite loop on a delay to run periodic scripts.