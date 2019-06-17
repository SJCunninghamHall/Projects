Write-Output "Removal started: $(Get-Date)"

$vmName = 'CSI-DBStandard'
$rgName = 'CSI_RGSQLStandard'
$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rgName



$azResourceParams = @{
 'ResourceName' = $vmName
 'ResourceType' = 'Microsoft.Compute/virtualMachines'
 'ResourceGroupName' = $rgName
}

$vmResource = Get-AzureRmResource @azResourceParams
$vmId = $vmResource.Properties.VmId



$diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
$diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Substring(0, 9), $vmId)
$diagSaRg = (Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
$saParams = @{
'ResourceGroupName' = $diagSaRg
'Name' = $diagSa
 }            

Get-AzureRmStorageAccount @saParams | Get-AzureStorageContainer | where { $_.Name-eq $diagContainerName } | Remove-AzureStorageContainer -Force



$vm | Remove-AzureRmVM -Force

$vm | Remove-AzureRmNetworkInterface -Force


$osDiskUri = $vm.StorageProfile.OSDisk.Vhd.Uri

$osDiskContainerName = $osDiskUri.Split('/')[-2]

# $osDiskStorageAcct = Get-AzureRmStorageAccount | where { $_.StorageAccountName -eq $osDiskUri.Split('/')[2].Split('.')[0] }

# $osDiskStorageAcct | Remove-AzureStorageBlob -Container $osDiskContainerName -Blob $osDiskUri.Split('/')[-1]

# Write-Verbose $osDiskStorageAcct

# $osDiskStorageAcct | Get-AzureStorageBlob -Container $osDiskContainerName -Blob "$($vm.Name)*.status" | Remove-AzureStorageBlob

if ($vm.DataDiskNames.Count -gt 0)
 {
     Write-Verbose -Message 'Removing data disks...'
     foreach ($uri in $vm.StorageProfile.DataDisks.Vhd.Uri)
     {
         $dataDiskStorageAcct = Get-AzureRmStorageAccount -Name $uri.Split('/')[2].Split('.')[0]
         
 $dataDiskStorageAcct | Remove-AzureStorageBlob -Container $uri.Split('/')[-2] -Blob $uri.Split('/')[-1] -ea Ignore
     }
 }

