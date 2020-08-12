# Provisioning internal cloned Hyper-V VM with Nested Virtualization on Rescue VM with the following administrative PowerShell on repair-stEdg-h_:
$vmswitch=Get-VMSwitch

# Set Hyper V VM name
$vmName = "newRescue";

# Create new VM
New-VM -Name "newRescue" -Generation 1 -MemoryStartupBytes 4096MB -SwitchName $vmswitch.Name;

# Make sure Disk 2 is offline
set-disk -number 2 -IsOffline $True;

# Attach Disk 2 to VM
Get-Disk 2 | Add-VMHardDiskDrive -VMName $vmName;

# Start VM
Start-VM -Name $vmName;
