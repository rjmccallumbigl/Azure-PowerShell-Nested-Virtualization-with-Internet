# az extension add -n vm-repair
# az vm repair create -g RG_PELO_EDGE_EAST_US -n stEdg-hdfxq --verbose

#resize VM to a v3
# az vm resize -g "repair-stEdg-hdfxq-20200807183824.638282" -n "repair-stEdg-h_" --size Standard_D2s_v3

# Newly created repair VM
$vmName = "repair-WS2019T_"
$resourceGroupName = "repair-WS2019TestingVM-20200812162035.322836"

# Install Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Users\rymccall\OneDrive - Microsoft\PowerShell\installHyperV.ps1'

# Sleep for 2 minutes until Hyper V is finished installing
Start-Sleep -s 120

# Set up Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Users\rymccall\OneDrive - Microsoft\PowerShell\provisionForNestedVirtualization.ps1'

# Create Hyper V VM remotely
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath 'C:\Users\rymccall\OneDrive - Microsoft\PowerShell\createNewHyperVVM.ps1'


