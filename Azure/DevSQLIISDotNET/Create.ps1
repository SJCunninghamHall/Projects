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
	
# Install IIS and the .NET framework using the custom script extension with the Set-AzVMExtension cmdlet.

Set-AzVMExtension `
    -ResourceGroupName $resourceGroup `
    -ExtensionName IIS `
    -VMName $vmName `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features"}' `
    -Location EastUS
	
# Create another subnet
# Create a second subnet for the SQL VM. Get the vNet using [Get-AzVirtualNetwork]{/powershell/module/az.network/get-azvirtualnetwork}.

$vNet = Get-AzVirtualNetwork `
   -Name $vNetName `
   -ResourceGroupName $resourceGroup
   
# Create a configuration for the subnet using Add-AzVirtualNetworkSubnetConfig.

Add-AzVirtualNetworkSubnetConfig `
   -AddressPrefix 192.168.0.0/24 `
   -Name devSQLSubnet `
   -VirtualNetwork $vNet `
   -ServiceEndpoint Microsoft.Sql

# Update the vNet with the new subnet information using Set-AzVirtualNetwork

$vNet | Set-AzVirtualNetwork

# Azure SQL VM
# Use a pre-configured Azure marketplace image of a SQL server to create the SQL VM. 
# We first create the VM, then we install the SQL Server Extension on the VM.


New-AzVm `
    -ResourceGroupName $resourceGroup `
    -Name "devSQLVM" `
	-ImageName "MicrosoftSQLServer:SQL2016SP1-WS2016:Enterprise:latest" `
    -Location eastus `
    -VirtualNetworkName $vNetName `
    -SubnetName "devSQLSubnet" `
    -SecurityGroupName "devNetworkSecurityGroup" `
    -PublicIpAddressName "devSQLPublicIpAddress" `
    -OpenPorts 3389,1401

# Use Set-AzVMSqlServerExtension to add the SQL Server extension to the SQL VM.

Set-AzVMSqlServerExtension `
   -ResourceGroupName $resourceGroup  `
   -VMName devSQLVM `
   -Name "SQLExtension" `
   -Location "EastUS"