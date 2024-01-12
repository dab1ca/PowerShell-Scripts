Param(
	[Parameter(Mandatory = $true)]
	[string] $subscriptionId,
    [Parameter(Mandatory = $true)]
	[string] $vmResourceGroupName,
    [Parameter(Mandatory = $true)]
	[string] $vmName,
    [Parameter(Mandatory = $true)]
	[string] $snapshotLocation,
    [Parameter(Mandatory = $true)]
	[string] $destinationStorageAccountName,
    [Parameter(Mandatory = $true)]
	[string] $destinationContainerName,
    [Parameter(Mandatory = $true)]
	[Int64] $numberOfCopies,
    [Parameter(Mandatory = $false)]
	[string] $destinationStorageAccountResourceGroup = $vmResourceGroupName
)

# Snapshot and backup names variables
$backupNumber = (Get-Date).DayOfYear
$backupNumberToDelete = (Get-Date).AddDays(-($numberOfCopies - 1)).DayOfYear
$snapshotName = "$vmName-disk-snapshot"
$sasExpiryDuration = 3600
$destinationVHDFileName = "$snapshotName-$backupNumber"

# Connect to Azure
Connect-AzAccount -Identity
Set-AzContext -SubscriptionObject (Get-AzSubscription -SubscriptionId $subscriptionId)

# Storage context
$destinationStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $destinationStorageAccountResourceGroup -Name $destinationStorageAccountName)[0].Value
$Context = New-AzStorageContext -StorageAccountName $destinationStorageAccountName  -StorageAccountKey $destinationStorageAccountKey
$vm = Get-AzVM -ResourceGroupName $vmResourceGroupName -Name $vmName

# Create new snapshot and check if an old snapshot exists to delete.	
$snapshotConfig =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $snapshotLocation -CreateOption copy
$oldSnapshot = Get-AzSnapshot -ResourceGroupName $vmResourceGroupName -SnapshotName $snapshotName

if ($null -ne $oldSnapshot) {
	Remove-AzSnapshot -ResourceGroupName $vmResourceGroupName -SnapshotName $snapshotName -Force
}

New-AzSnapshot -Snapshot $snapshotConfig -SnapshotName $snapshotName -ResourceGroupName $vmResourceGroupName 

# Get snapshot authentication SAS
$sas=(Grant-AzSnapshotAccess -ResourceGroupName $vmResourceGroupName -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access 'Read')

# Delete oldest snapshot backup(if exists)
$oldestSnapshotBackup = Get-AzStorageBlob -Blob "$snapshotName-$backupNumberToDelete" -Container $destinationContainerName -Context $Context
if ($null -ne $oldestSnapshotBackup) {
	$oldestSnapshotBackup | Remove-AzStorageBlob 
}

# Create a new snapshot backup
Start-AzStorageBlobCopy -DestBlob $destinationVHDFileName -DestContainer $destinationContainerName -DestContext $Context -AbsoluteUri $sas.AccessSAS
