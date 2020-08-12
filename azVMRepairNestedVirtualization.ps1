# Runs az vm repair on a problem VM to create a Rescue VM with the source VM's OS disk attached as a data disk. 
# Then configures the new Rescue VM for Hyper V, creates a new Hyper V VM, and sets it up with the data disk as a new primary disk (with internet).
# Run this file with the proper parameters.
# Make sure you have the following files as well:
#   .\dependencies\installHyperV.ps1
#   .\dependencies\provisionForNestedVirtualization.ps1
#   .\dependencies\createNewHyperVVM.ps1

#Set the Parameters for the script
param (
        [Parameter(Mandatory=$true, ParameterSetName="vmName", HelpMessage="The name of the source VM.")]
        [string] 
        $vmName,
        [Parameter(Mandatory=$true, ParameterSetName="resourceGroupName", HelpMessage="The name of the source VM's Resource Group.")]
        [string] 
        $resourceGroupName,
        [Parameter(Mandatory=$true, ParameterSetName="rescueUsername", HelpMessage="The username you will use on your Rescue VM.")]
        [string]
        $rescueUsername,
        [Parameter(Mandatory=$true, ParameterSetName="rescuePassword", HelpMessage="The password you will use on your Rescue VM.")]
        [SecureString]
        $rescuePassword
        )

# Make sure vm-repair is installed and updated
az extension add -n vm-repair
az extension update -n vm-repair

# az vm repair create -g RG_PELO_EDGE_EAST_US -n stEdg-hdfxq --repair-username username --repair-password password!234 --verbose

# Create repair VM, attach OS disk from source VM
$rescueVM = az vm repair create -g $resourceGroupName -n $vmName --repair-username $rescueUsername --repair-password $rescuePassword --verbose

# Grab repair VM name and Resource Group from returned 'az vm repair' results
# https://regexr.com/
$RescueVMRegex = [regex]"(repair-)\S+"
$RescueVMRegexResults = $RescueVMRegex.Matches($rescueVM[2]) 
$rescueVMName = $RescueVMRegexResults[0].Value;
$rescueVMResourceGroup = $RescueVMRegexResults[1].Value;

# Resize VM to a v3
az vm resize -g $rescueVMResourceGroup -n $rescueVMName --size Standard_D2s_v3

# Install Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\installHyperV.ps1'

# Sleep for 2 minutes until Hyper V is finished installing
Start-Sleep -s 120

# Set up Hyper V remotely, change your script path accordingly
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\provisionForNestedVirtualization.ps1'

# Create Hyper V VM remotely
Invoke-AzVMRunCommand -ResourceGroupName $rescueVMResourceGroup -Name $rescueVMName -CommandId 'RunPowerShellScript' -ScriptPath '.\dependencies\createNewHyperVVM.ps1'


