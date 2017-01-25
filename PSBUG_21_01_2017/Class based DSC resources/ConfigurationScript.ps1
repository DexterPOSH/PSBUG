Configuration DeployVM {
param (
[string[]]$NodeName = 'localhost',
 
[ValidateSet("Present","Absent")]
[string]$Ensure = "Present"
)
 
    Import-DscResource -module cManageVMDeployment
    
    Node $NodeName {
    
        cManageVMDeployment NewVm {
        VmName = 'TestVM01'
        Ensure = 'Present'
        }
    
    }
}
 
DeployVM -OutputPath "C:\Scripts\DeployVM"
 
Start-DscConfiguration -Path "C:\Scripts\DeployVM" -ComputerName localhost -Wait -Verbose