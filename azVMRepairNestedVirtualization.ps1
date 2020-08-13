###########################################################################################################################################################
<#
# .SYNOPSIS
# Configures Rescue VM for troubleshooting using Nested Virtualization.
#
# .DESCRIPTION
#       Configures Rescue VM for troubleshooting using Nested Virtualization.
#       Runs az vm repair on a problem VM to create a Rescue VM with the source VM's OS disk attached as a data disk. 
#       Then configures the new Rescue VM for Hyper V, creates a new Hyper V VM, and sets it up with the data disk as a new primary disk (with internet).
#
#       First change the PowerShell directory to whatever directory this script is in.
#       Then run this file with the proper parameters.
#
#       Make sure you have the following files as well:
#               .\dependencies\installHyperV.ps1
#               .\dependencies\provisionForNestedVirtualization.ps1
#               .\dependencies\createNewHyperVVM.ps1
#
# .PARAMETER vmName
#       The name of the source VM.
#
# .PARAMETER resourceGroupName
#       The name of the source VM's Resource Group.
#
# .PARAMETER rescueUsername
#       The username you will use on your Rescue VM.
#
# .PARAMETER rescuePassword
#       The password you will use on your Rescue VM.
#
# .EXAMPLE
#       azVMRepairNestedVirtualization -n vmName -g ResourceGroup -u Username -p Password!234
#>
###########################################################################################################################################################

#Set the Parameters for the script
param (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the source VM.")]
        [Alias('n')]
        [string] 
        $vmName,
        [Parameter(Mandatory = $true, HelpMessage = "The name of the source VM's Resource Group.")]
        [Alias('g')]
        [string] 
        $resourceGroupName,
        [Parameter(Mandatory = $true, HelpMessage = "The username you will use on your Rescue VM.")]
        [Alias('u')]
        [string]
        $rescueUsername,
        [Parameter(Mandatory = $true, HelpMessage = "The password you will use on your Rescue VM.")]
        [Alias('p')]
        [SecureString]
        $rescuePassword
)

# Make sure vm-repair is installed and updated
az extension add -n vm-repair
az extension update -n vm-repair

# Create repair VM, attach OS disk from source VM
try {
        $rescueVM = az vm repair create -g $resourceGroupName -n $vmName --repair-username $rescueUsername --repair-password $rescuePassword --verbose
}
catch {
        Write-Host $Error[0]
        return
}

# Grab repair VM name and Resource Group from returned 'az vm repair' results
# https://regexr.com/
$RescueVMRegex = [regex]"(repair-)\S+[^' ]"
$RescueVMRegexResults = $RescueVMRegex.Matches($rescueVM[2]) 
$rescueVMName = $RescueVMRegexResults[0].Value
$rescueVMResourceGroup = $RescueVMRegexResults[1].Value

# Resize VM to a v3
az vm resize -g $rescueVMResourceGroup -n $rescueVMName --size Standard_D2s_v3

# Make sure VM has started
Start-AzVM -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName

# Verify and enable boot diagnostics
$storage = Get-AzStorageAccount -ResourceGroupName $rescueVMResourceGroup
if ($storage) {
        $getRescueVM = Get-AzVM -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName
        try {
                Set-AzVMBootDiagnostic -VM $getRescueVM -Enable -ResourceGroupName $rescueVMResourceGroup -StorageAccountName $storage.StorageAccountName
        }
        catch {
                Write-Host "Could not enable boot diagnostics, please enable manually!"
                Write-Host $Error[0]
        }       
}

# Install Hyper V remotely
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\installHyperV.ps1'

# Sleep for 2 minutes until Hyper V is finished installing and VM is done rebooting
Start-Sleep -s 120

# Set up Hyper V remotely
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\provisionForNestedVirtualization.ps1'

# Create Hyper V VM remotely
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\createNewHyperVVM.ps1'
