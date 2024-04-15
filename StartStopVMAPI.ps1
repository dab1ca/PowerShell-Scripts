Param(
	[Parameter(Mandatory = $true, HelpMessage = "Enter the subscription IDs separated by comma")]
	[string] $subscriptionIds,
    [Parameter(Mandatory = $true)]
	[string] $action,
	[Parameter(Mandatory = $false)]
	[string] $tagKey,
    [Parameter(Mandatory = $false)]
	[string] $tagValue
)

Connect-AzAccount -Identity

$subscriptionIdsSplit = $subscriptionIds.Split(",")

# Define the desired state for Virtual Machines
$desiredState = ""
if ($action -eq "start") {
    $desiredState = "VM running"
}
elseif ($action -eq "stop" -or $action -eq "deallocate") {
    $desiredState = "VM deallocated"
    $action = "deallocate"
} 
else {
    Write-Output "Please enter valid action (start/stop)"
    exit
}

# Loop through each subscription
foreach ($subscriptionId in $subscriptionIdsSplit) {
    Set-AzContext -SubscriptionObject (Get-AzSubscription -SubscriptionId $subscriptionId)

    # Check if tag key is provided and get VMs, based on condition
    if ($null -eq $tagKey) {
        $VMs = Get-AzVM | Select-Object Name, ResourceGroupName
    }
    else {
        $VMs = Get-AzVM | Where-Object {$_.Tags.Keys -eq $tagKey -and $_.Tags.Values -eq $tagValue} | Select-Object Name, ResourceGroupName
    }

    # Get the access token for API authentication
    $token = (Get-AzAccessToken).Token
    $headers = @{
        "Authorization" = "Bearer $token"
    }

    # Loop through each VM
    foreach ($VM in $VMs) {
        $VMName = $VM.Name
        $VMResourceGroup = $VM.ResourceGroupName
        # Get current VM state
        $VMStatus = (Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroup -Status).Statuses[1].DisplayStatus
        
        # Check if the VM is in the desired state
        if ($VMStatus -ne $desiredState) {
            # Send the request to start/stop the VM
            $url = [string]::Concat("https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$VMResourceGroup/providers/Microsoft.Compute/virtualMachines/$VMName/$action","?api-version=2023-03-01")   
            $response = Invoke-Webrequest -Headers $headers -Method Post -Uri $url
            
            if ($response.StatusDescription -eq "Accepted") {
                Write-Output "$($VM.Name) $action request accepted" 
            }
            else
            {
                Write-Output "Could not $action $VMName, current status $VMStatus"
            }
        }             
        else {
        # Output the status of the VM
            Write-Output "VM $VMName is already in status '$VMStatus'"
        }
    }
}
