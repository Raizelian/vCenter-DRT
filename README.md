# vCenter Data Report Tool

Tool that generates .csv files containing a list of useful information about virtual machines on a chosen vCenter, such as:
- Name
- PowerState
- ResourcePool
- Folder
- PoweredOffTime (vcenter-drt-poweredoff.ps1)

The basic script, **vcenter-drt.ps1**, gets the current state of a virtual machine (either powered on, or powered off) and reports on the information listed above.

The **vcenter-drt-poweredoff.ps1** script also evaluates the VM's power state and if found equal to `PoweredOff` then elaborates the date and time of that event; if it can't find any PoweredOff event then it looks for the `LastWriteTime` of the .nvram file of that virtual machine. The .nvram file is searched for in every datastore linked to a VM and, if not present, one can suppose the VM was just imported and never powered on - or orphaned.

The final result is either the `vms_report-{vcenter}.csv` or `poweredoff-vms_report-{vcenter}.csv`  file containing all the gathered information.


## Configuration

Edit the `ro_config.ini` file with the necessary information for the needed vCenter connection.
For security reasons, it would be better to not use a full admin account for the connection: this script works fine with a **read-only account to which only the DataStore.Browse privilege has been added**.

```
[vCenter]
vCenter_Host = vcenter.site.com
vCenter_User = user
vCenter_Password = password
```

## Usage

After editing the `ro_config.ini` file you just need to run the script; the only required module is [VMware PowerCLI](https://developer.vmware.com/web/tool/vmware-powercli/) but the script handles its installation if not found on the system.

It's suggested not to remove the `Write-Host` cmdlets in order to have a running visual indicator of the processing of each VM (can be useful on big pools of VMs).
Estimated wait times based on real use cases:
- 2500+ VMs, only looking for PoweredOff VMs: couple of hours to find around 400 total PoweredOff VMs and all their info
- 100-ish VMs, only looking for PoweredOff VMs: several minutes

## TODO

- [X] Basic info gathering
- [X] Extract information about PoweredOff VMs
- [X] Add .nvram LastWriteTime evaluation
- [X] Handle any name exclusion as needed, es. templates
- [X] Import vCenter connection configuration from .ini
- [ ] Add optional listing of datastores in basic info gathering
- [ ] Add caching for optimization purposes
