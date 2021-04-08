# Azure SQL VM
# Use a pre-configured Azure marketplace image of a SQL server to create the SQL VM. 
# We first create the VM, then we install the SQL Server Extension on the VM.

$vmName = "devSQLVM"
$vNetName = "devIISSQLvNet"
$resourceGroup = "devIISSQLGroup"

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