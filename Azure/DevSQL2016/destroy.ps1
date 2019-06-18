# Get rid of the resource group to remove all artifacts associated with it, thereby removing the server completely. Use the RG name supplied in the deploy.ps1 script.
Remove-AzResourceGroup -Name devRG
