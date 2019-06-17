$vmName = "IISVM"
$vNetName = "devIISSQLvNet"
$resourceGroup = "devIISSQLGroup"

# Create another subnet
# Create a second subnet for the SQL VM. Get the vNet using [Get-AzVirtualNetwork]{/powershell/module/az.network/get-azvirtualnetwork}.

$vNet = Get-AzVirtualNetwork `
   -Name $vNetName `
   -ResourceGroupName $resourceGroup
   
# Create a configuration for the subnet using Add-AzVirtualNetworkSubnetConfig.

Add-AzVirtualNetworkSubnetConfig `
   -AddressPrefix 192.168.0.0/24 `
   -Name mySQLSubnet `
   -VirtualNetwork $vNet `
   -ServiceEndpoint Microsoft.Sql

# Update the vNet with the new subnet information using Set-AzVirtualNetwork

$vNet | Set-AzVirtualNetwork
