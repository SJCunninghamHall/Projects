# Install IIS and the .NET framework using the custom script extension with the Set-AzVMExtension cmdlet.

$vmName = "IISVM"
$vNetName = "devIISSQLvNet"
$resourceGroup = "devIISSQLGroup"

Set-AzVMExtension `
    -ResourceGroupName $resourceGroup `
    -ExtensionName IIS `
    -VMName $vmName `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features"}' `
    -Location EastUS