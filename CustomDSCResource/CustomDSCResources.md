# Custom DSC resource development

DSC resource must have the following:
- A Schema MOF file containing the properties of a DSC resource
- A Module Manifest file that describes the module and specifies how it should be
processed


Optionally, the DSC resource can contain any .ps1 files or other PowerShell script modules files required and the help content as text files

## DSC Resource Schema
The schema MOF of a DSC resource defines the properties of a resource.

- Each custom resource class should inherit from the OMI_BaseResource class.
- ClassVersion and FriendlyName attributes are mandatory. 

### Qualifiers
**Key** The key qualifier on a property indicates that the property uniquely identifies the resource instance. --> [Key] string VMName;

**Write** The write qualifier indicates that a value can be assigned to the property in a configuration script. --> [write] string Description;

Read The read qualifier indicates that the property value cannot be assigned or changed in a configuration script. --> [read] string VMID;

**Description** This qualifier is used to provide a description for a property. This is used along with read or write or key qualifiers. --> [Key, description("Specifies the name of the VM to be created.")]string VMName;

**Required** This qualifier specifies that the property value is mandatory and cannot be null. Make a note that this is not the same as the key qualifier. The key qualifier uniquely identifies a resource instance. --> [required] string VHDPath;


**ValueMap and Values** This restricts the values that can be assigned to a property to that defined in ValueMap. --> [write,ValueMap{"Present","Absent"},Values{"Present","Absent"}] string Ensure;

```PowerShell
[ClassVersion("1.0.0.0"), FriendlyName("VirtualMachine")]
class MyDSC_VirtualMachine : OMI_BaseResource
{
[key, Description("Specifies the name of the Virtual Machine.")] string VMName;
[write, Description("Specifies description for the Virtual Machine")] string Description;
[required, Description("Specifies the path of the VHD")] string VHDPath;
[read, Description("Specifies the virtual machine identifer")] string VMID;
[write,ValueMap{"Present", "Absent"},Values{"Present", "Absent"}] string Ensure;
};
```

## DSC Resource Module

Mandatory functions in a DSC resource module

- Get-TargetResource 

    - This function is used to retrieve the current state of the configuration.
      For example, by taking the key resource properties as input, the function should check the state of the resource on the target system and return all its properties.

    - Input - The resource properties identified as key properties in the schema MOF
    - Output - A configuration hash table containing the values of all resource instance properties in the current state

- Set-TargetResource 

    - This function should contain the logic required to perform the configuration change. This function is used to ensure that the resource instance is in the requested state.
      Ideally, the Ensure property must be used to identify the requested state.
    - Input - The resource properties identified as key properties and any other optional properties defined in the schema MOF
    - Output - None

- Test-TargetResource 

    - This function is used to identify if the resource instance is in a desired state or not. The output from this function is used to decide if the Set-TargetResource function must be called or not. Again, the value of the Ensure parameter is used to test if the resource instance is in a desired state or not.
    - Input - This function must have the same parameters as the Set-TargetResource function. The Test-DscConfiguration cmdlet calls this function to verify if the resource instance is in a desired state or not.
    - Output - A Boolean value indicating if the resource instance is in a desired state (True) or not (False)


![](DSCresourceexecutionflow.png)

## Packaging DSC Resource Modules

Two ways of packaging the DSC resource modules.
 1. All files in the resource module in one folder.
 
    ![](DSCResourceSimpleFolder.png)

 2. Nested PowerShell module

    ![](DSCResourceNestedModule.png)