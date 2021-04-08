# Create IIS VM

$vmName = "IISVM"
$vNetName = "devIISSQLvNet"
$resourceGroup = "devIISSQLGroup"

New-AzVm `
    -ResourceGroupName $resourceGroup `
    -Name $vmName `
    -Location "East US" `
    -VirtualNetworkName $vNetName `
    -SubnetName "devIISSubnet" `
    -SecurityGroupName "devNetworkSecurityGroup" `
	-AddressPrefix 192.168.0.0/16 `
    -PublicIpAddressName "devIISPublicIpAddress" `
    -OpenPorts 80,3389