# xSecPol

The **xSecPol** module contains the **xSecPol** DSC resource for setting up and configuring Windows local security policy settings for Windows.

Currently only Service and Batch logon are supported, but this will be expanded to support other logon types as well.

This should support groups also, but this is untested currently, hence the variable "UserSID"

## Resources

### xSecPol

* **UserSID**: UserSID of Git to Install.
* **PrivilegeRight**: Path to the Git Installer. The machine account must have access to this path if hosted on anetwork location.
* **InstallerArchitecture**: Architecture of the Git installer (x86 or x64)
* **Ensure**: Specifies if git should be Present, Absent, or AnyUserSIDPresent (any version installed).

## Examples
#### Ensure that the specified account has permissiosn to run batch jobs.

This configuration ensures that the specified account has permissions to run batch jobs"

```powershell
Configuration GrantBatchPerms
{
    Import-DscResource -Name PCM_xSecPol
    # A Configuration block can have zero or more Node blocks
    Node localhost
    {
        xSecPol BatchJobs
        {
            Ensure = "Present" 
            UserSID   = S-1-5-21-917267712-1342860078-1792151419-500
            PrivilegeRight = "Batch"
        }
    }
} 

GrantBatchPerms
```

### Ensure that some account can run services.

This configuration ensures that the specified account has the ability to run Windows services.

```powershell
Configuration GrantServicePerms
{
    Import-DscResource -Name PCM_xSecPol
    Node localhost
    {
        # Next, specify one or more resource blocks

        xSecPol WindowsServicePerms
        {
            Ensure = "Present" 
            UserSID   = S-1-5-21-917267712-1342860078-1792151419-500
            PrivilegeRight = "Service"
        } 
    }
}
GrantServicePerms
```

### Remove Service account access

This example removes a SID's access to run a service

```powershell
Configuration RemoveServicePerms
{
    Import-DscResource -Name PCM_xSecPol
    Node localhost
    {
        xSecPol RemoveWindowsServicePerms
        {
            Ensure = "Absent" 
            UserSID   = S-1-5-21-917267712-1342860078-1792151419-500
            PrivilegeRight = "Service"
        }
    }
} 

RemoveServicePerms
```
