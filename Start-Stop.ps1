# Set Parameters - will loop a RG if added or the entire sub if no RG is provided in input parameters.
Param(
	[Parameter(Mandatory = $true)]
	[string] $subscriptionId,
	[Parameter(Mandatory = $false)]
	[string] $resourceGroupName,
	[Parameter(Mandatory = $true)]
	[string] $action
)

# Authenticate to Azure
function main
{
	Connect-AzAccount -Identity
	$contextSub = Get-AzSubscription -SubscriptionId $subscriptionId
	Set-AzContext -SubscriptionObject $contextSub

	switch ($action)
	{
		'start'
		{
			$VMList = GetVMList($resourceGroupName)
			StartVMsFromList($VMList)
		}
		'stop'
		{
			$VMList = GetVMList($resourceGroupName)
			StopVMsFromList($VMList)
		}
		default
		{
			Write-Output "No action selected"
		}
	}
	return
}
# Get a list of VMswaa

function GetVMList ([string]$resourceGroupName)
{
	if ($resourceGroupName -eq "")
	{
		$VMList = Get-AzVM
	}
	else
	{
		$VMList = Get-AzVM -ResourceGroupName $resourceGroupName
	}
	return $VMList
}

function StartVMsFromList ($VMList)
{
	Foreach ($VM in $VMList) 
	{
		$VMName = $VM.Name
		$VMResourceGroupName = $VM.ResourceGroupName
		$status = (Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroupName -status).Statuses[1].DisplayStatus

		if ($status -eq 'VM running')
		{
			Write-Output "Virtual Machine $VMName already running"
		}
		else 
		{
			Write-Output "Virtual Machine $VMName is stopped. Starting $VMName"
			Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
		}
	}
	return
}

function StopVMsFromList ($VMList)
{
	Foreach ($VM in $VMList) 
	{
		[string]$VMName = $VM.Name
		[string]$VMResourceGroupName = $VM.ResourceGroupName
		$status = (Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroupName -status).Statuses[1].DisplayStatus
		if ($status -eq 'VM running')
		{
			Write-Output "Virtual Machine $VMName is currently running. Stopping $VMName"
			Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force
		}
		else 
		{
			Write-Output "Virtual Machine $VMName already stopped"
		}
	}
	return
}

main
