Function Move-AllFMSO
    {
    Param
        (
        $ComputerName
        )

    Move-ADDirectoryServerOperationMasterRole -Identity $ComputerName -OperationMasterRole 0,1,2,3,4 -Confirm:$false
    netdom query fsmo
    }


Move-AllFMSO 'Server10'

Uninstall-ADDSDomainController