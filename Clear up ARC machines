#Enter Subscription To clean and days since last status update
Param 
(    
  [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
  [String] 
  $subscriptionId,
	[Parameter(Mandatory=$false)]
	[Int] 
	$idleTime = 10
)

#Authenticate to Azure
Connect-AzAccount -Identity
Set-AzContext -SubscriptionObject (Get-AzSubscription -SubscriptionId $subscriptionId)

#Get machines that are Disconnected/Expired
$disconnectedMachinesList = Get-AzConnectedMachine | Where-Object {$_.Status -ne "Connected"}

#Delete stale machines
foreach($ARCServer in $disconnectedMachinesList) {
	$name = $ARCServer.Name
	$status = $ARCServer.Status
	$lastChange = $ARCServer.LastStatusChange
	if($lastChange -lt (Get-Date).AddDays(-($idleTime))) {
		Write-Output "Server $name is $status and has been inactive for more than $idleTime days. Deleting from Azure"
		#Remove-AzConnectedMachine -InputObject $ARCServer
	}
	else {
		Write-Output "Server $name is $status. Please check if the machine needs to be reviewed. Machine will be automatically deleted if not active for $idleTime days"
	}
}
