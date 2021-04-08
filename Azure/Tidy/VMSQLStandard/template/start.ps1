Write-Output "Deployment started: $(Get-Date)"

Write-Output "Changing permissions to allow script run: $(Get-Date)"
Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force
Write-Output "Permissions changed to allow script run: $(Get-Date)"

.\deploy.ps1 -subscriptionId e262bc47-dee1-4da6-b241-547fe9c6b84d -resourceGroupName CSI_RGSQLStandard -deploymentName CSISQLStandard -resourceGroupLocation eastus
Write-Output "Deployment completed: $(Get-Date)"
