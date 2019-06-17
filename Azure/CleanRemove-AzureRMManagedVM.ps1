<#
.SYNOPSIS
    .Script to remove Azure VM with all associated unmanaged disks.
.DESCRIPTION
    .This script removes Azure VM with all associated managed disks.

.PARAMETER SubscriptionName
    Optional parameter. Specify the Azure subscription name which will be set as a default subscription for executing the script.

.PARAMETER VMName
   Mandatory parameter. Name of the VM to be converted from unmanaged disks to VM with managed disks.

.PARAMETER ResourceGroupName
   Mandatory parameter. Name of the resource group containing the virtual machine.

.DeleteManagedDisks
   Switch. Set if the all managed disks needs to be deleted along with the Virtual Machine.
#>

Param
     (
         [Parameter(Mandatory=$false)]
         [string]
         $SubscriptionName,

         [Parameter(Mandatory=$true)]
         [string]
         $VMName,

         [Parameter(Mandatory=$true)]
         [string]
         $ResourceGroupName,

         [Parameter(Mandatory=$false)]
         [switch]
         $DeleteManagedDisks

     )

function Get-ManagedDisks($VM){

    $managedDisks = @()
    Write-Host "Collecting managed disks (OS and Data Disks) information from the VM."

    $managedDisks += $VM.StorageProfile.OsDisk.ManagedDisk.Id

    foreach ($disk in $VM.StorageProfile.DataDisks){
    
        $managedDisks += $disk.ManagedDisk.Id
    }

    return $managedDisks

}

function Remove-VMDisk($disks){

    foreach ($diskId in $disks){

        Write-Host "Removing disk $diskId from $VMName"    

        #Force remove managed disk by Resource Id
        Remove-AzureRmResource -ResourceId $diskId -Force

        Write-Host "Removed disk $diskId from $VMName" -ForegroundColor Green  
    }
}

try{

    #Login to Azure Subscription
    Login-AzureRmAccount
    $subscriptions = Get-AzureRmSubscription -ErrorAction Stop

    #Switch Subscription if it is mentioned
    if($SubscriptionName -ne $null){

        Set-AzureRmContext -SubscriptionName $subscriptions.SubscriptionName
        Write-Host "Setting default subscription."
    }

    #Get Azure RM VM
    Write-Host "Getting virtual machine with specified name."
    $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop

    if($VM -ne $null){
    
        #Function call to get managed disks of VM
        $vmManagedDisks = Get-ManagedDisks -VM $VM

        #Remove VM
        Write-Host "Removing $VMName"
        Remove-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force
        Write-Host "Removed $VMName successfully." -ForegroundColor Green

        if($DeleteManagedDisks){

            #Function call to remove managed disks
            Remove-VMDisk -disks $vmManagedDisks

            Write-Host "Removed all associated managed disks of $VMName"
        }
    }

}
catch{

    Write-Host "Caught an exception:" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
}