#Azure Account Variables
$subscr = "Azure Pass - Big Blue"
$StorageAccountName = "labvmpremsa"
$StorageResourceGroup = "LABCLUVMRG"

#set Azure Subscriptions and Storage Account Defaults
Get-AzureRmSubscription -SubscriptionName $subscr | Select-AzureRmSubscription -WarningAction SilentlyContinue
$StorageAccount = Get-AzureRmStorageAccount -name $StorageAccountName -ResourceGroupName $StorageResourceGroup | set-azurermstorageaccount -WarningAction SilentlyContinue

##Global Variables
$resourcegroupname = "LABCLUVMRG"
$location = "Central US"

## Compute Variables
$VMName = "VMLABDC01"
$ComputerName = "LABDC01"
$VMSize = "Standard_DS2_v2"
$OSDiskName = $VMName + "OSDisk"

## Network Variables
$Interface1Name = $VMName + "_int1"
$Interface2Name = $VMName + "_int2"
$Subnet1Name = "public"
$Subnet2Name = "cluster"
$VNetName = "clusterlan"


###########################################################
#Do Not Edit Below This Point                             #
###########################################################

## Network Interface Creation
$PIp1 = New-AzureRmPublicIpAddress -Name $Interface1Name -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic -WarningAction SilentlyContinue
$VNet = Get-AzureRmVirtualNetwork -name $VNetName -ResourceGroupName $resourcegroupname -WarningAction SilentlyContinue
$Interface1 = New-AzureRmNetworkInterface -Name $Interface1Name -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIp1.Id -WarningAction SilentlyContinue
$Interface2 = New-AzureRmNetworkInterface -Name $Interface2Name -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId "/subscriptions/48752a98-beec-43e1-ac81-00a4663df389/resourceGroups/LABCLUVMRG/providers/Microsoft.Network/virtualNetworks/clusterlan/subnets/cluster" -WarningAction SilentlyContinue

## Create VM Object
$Credential = Get-Credential
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -WarningAction SilentlyContinue
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate -WarningAction SilentlyContinue
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version "latest" -WarningAction SilentlyContinue
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface1.Id -WarningAction SilentlyContinue
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface2.Id -WarningAction SilentlyContinue
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd" 
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage -WarningAction SilentlyContinue
$VirtualMachine.NetworkProfile.NetworkInterfaces.Item(0).Primary = $true 

## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -WarningAction SilentlyContinue