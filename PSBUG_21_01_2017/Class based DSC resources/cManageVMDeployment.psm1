# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.    
    Absent
    # The resource must be present.    
    Present
}

# [DscResource()] indicates the class is a DSC resource.
[DscResource()]
class cManageVMDeployment
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$VMName

    # Mandatory indicates the property is required and DSC will guarantee it is set.
    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    # NotConfigurable properties return additional information about the state of the resource.
    # For example, a Get() method might return the date a resource was last modified.
    # NOTE: These properties are only used by the Get() method and cannot be set in configuration.        
    [DscProperty(NotConfigurable)]
    [Nullable[datetime]] $CreationTime
<#
    [DscProperty()]
    [ValidateSet("val1", "val2")]
    [string] $P4
#> 

    # Sets the desired state of the resource.
    [void] Set()
    {  
        Write-Verbose "Set() Method has been invoked"
        $VMExits = $this.TestVM()

        Try {
            
            If ($this.Ensure -eq [Ensure]::Present) {
            
                If (!$VMExits) {

                    Write-Verbose "Creating the VM $($this.VMName)"
                    $this.CreateVM()
                }
            }

            Else {
            
                If ($VMExits) {

                    Write-Verbose "Deleting the VM $($this.VMName)"
                    $this.DeleteVM()

                }
            }
        } Catch {
        
        Write-Verbose "Action failed with the error $_"
        
        }     
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        Write-Verbose "Test() Method has been invoked"
        $VMPresent = $this.TestVM()
        If ($this.Ensure -eq [Ensure]::Present) {

            Write-Verbose "Test() Method is returning Desired state of the machine as $VMPresent"
            return $VMPresent

        } Else {

            Write-Verbose "Test() Method is returning Desired state of the machine as $(-not $VMPresent)"
            return -not $VMPresent
        
        }
    }    
    # Gets the resource's current state.
    [cManageVMDeployment] Get()
    {   
        Write-Verbose "Get() Method has been invoked"
        $VMPresent =  $this.TestVM()
        If ($VMPresent) {
        
            $this.CreationTime = (Get-VM -name $this.VMName).CreationTime
            $this.Ensure = [Ensure]::Present
        } Else {
        
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent
        } 

        # Return this instance or construct a new instance.
        return $this 

    } 
    
    #Helper method for creating the VM
    [void] CreateVM()
    {
        #Creating the VM
        Write-Verbose "CreateVM() Method has been invoked"
        New-VM -Name $this.VMName 
    
    }

    #Helper method for deleting the VM
    [void] DeleteVM()
    {
        #Deleting the VM
        Write-Verbose "DeleteVM() Method has been invoked"
        Remove-VM -Name $this.VMName
    
    } 

    #Helper method for checking availability of the VM
    [bool] TestVM()
    {
        Write-Verbose "TestVM() Method has been invoked"
        $VM = Get-VM -Name $this.VMName -ErrorAction SilentlyContinue

        $Present = $true

        if (!$VM) {
    
            $Present = $false

        }

        return $Present
    
    }
      
}

