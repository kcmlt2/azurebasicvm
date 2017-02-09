Login-AzureRmAccount -TenantId 5c8085d9-1e88-4bb6-b5bd-e6e6d5b5babd
Get-AzureRmSubscription -SubscriptionName "Azure Pass - Big Blue" | Select-AzureRmSubscription
$location = "centralus"
$myResourceGroup = "kcmlt2RG"
New-AzureRmResourceGroup -Name $myResourceGroup -Location $location
$myStorageAccountName = "kcmlt2sa"
$myStorageAccount = New-AzureRmStorageAccount -ResourceGroupName $myResourceGroup `
-Name $myStorageAccountName -SkuName "Standard_LRS" -Kind "Storage" -Location $location
$mySubnet = New-AzureRmVirtualNetworkSubnetConfig -Name "kcmlt2Subnet" -AddressPrefix 10.0.0.0/24
$myVnet = New-AzureRmVirtualNetwork -Name "kcmlt2Vnet" -ResourceGroupName $myResourceGroup `
-Location $location -AddressPrefix 10.0.0.0/16 -Subnet $mySubnet
$myPublicIp = New-AzureRmPublicIpAddress -Name "kcmlt2PublicIp" -ResourceGroupName $myResourceGroup `
-Location $location -AllocationMethod Dynamic
$myNIC = New-AzureRmNetworkInterface -Name "kcmlt2NIC" -ResourceGroupName $myResourceGroup -Location $location -SubnetId $myVnet.Subnets[0].Id -PublicIpAddressId $myPublicIp.Id
$cred = Get-Credential -Message "Type the name and password of the local administrator account."
$myVm = New-AzureRmVMConfig -VMName "kcmlt2VM" -VMSize "Standard_DS1_v2"
$myVM = Set-AzureRmVMOperatingSystem -VM $myVM -Windows -ComputerName "kcmlt2srvr" -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$myVM = Set-AzureRmVMSourceImage -VM $myVM -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
$myVM = Add-AzureRmVMNetworkInterface -VM $myVM -Id $myNIC.Id
$blobPath = "vhds/myOsDisk1.vhd"
$osDiskUri = $myStorageAccount.PrimaryEndpoints.Blob.ToString() + $blobPath
$myVM = Set-AzureRmVMOSDisk -VM $myVM -Name "myOsDisk1" -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $myResourceGroup -Location $location -VM $myVM