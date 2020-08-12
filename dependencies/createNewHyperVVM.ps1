# Provisioning internal cloned Hyper-V VM with Nested Virtualization on Rescue VM with the following administrative PowerShell
# https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-machine-in-hyper-v

# Get current switch, should have been created after running .\dependencies\provisionForNestedVirtualization.ps1
$vmswitch=Get-VMSwitch

# Set Hyper V VM name
$vmName = "newRescueVM";

# Create new VM
New-VM -Name $vmName -Generation 1 -MemoryStartupBytes 4096MB -SwitchName $vmswitch.Name;

# Make sure Disk 2 is offline
set-disk -number 2 -IsOffline $True;

# Attach Disk 2 to VM
Get-Disk 2 | Add-VMHardDiskDrive -VMName $vmName;

# Start VM
Start-VM -Name $vmName;
