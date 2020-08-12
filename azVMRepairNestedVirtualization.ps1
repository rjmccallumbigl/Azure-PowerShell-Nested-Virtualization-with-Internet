# Runs az vm repair on a problem VM to create a Rescue VM with the source VM's OS disk attached as a data disk. 
# Then configures the new Rescue VM for Hyper V, creates a new Hyper V VM, and sets it up with the data disk as a new primary disk (with internet).
# Run this file with the proper parameters.
# Make sure you have the following files as well:
#   .\dependencies\installHyperV.ps1
#   .\dependencies\provisionForNestedVirtualization.ps1
#   .\dependencies\createNewHyperVVM.ps1

# Create repair VM
az extension add -n vm-repair
az vm repair create -g RG_PELO_EDGE_EAST_US -n stEdg-hdfxq --repair-username username --repair-password password!234 --verbose

#resize VM to a v3
az vm resize -g "repair-stEdg-hdfxq-20200807183824.638282" -n "repair-stEdg-h_" --size Standard_D2s_v3

# Newly created repair VM
$vmName = "repair-WS2019T_"
$resourceGroupName = "repair-WS2019TestingVM-20200812162035.322836"

# Install Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\installHyperV.ps1'

# Sleep for 2 minutes until Hyper V is finished installing
Start-Sleep -s 120

# Set up Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\provisionForNestedVirtualization.ps1'

# Create Hyper V VM remotely
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\createNewHyperVVM.ps1'


