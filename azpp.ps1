# First, we create our variables 
$location = EastUS
$resourceGroup = Az-powerpuff 
$virtualMachineName = Az-powerpuff-VM
$virtualnetwork = Az-powerpuff-vnet
$Cred = Get-Credential -Message "Enter a username and password for the virtual machine."


# Create resource group
New-AzResourceGroup -ResourceGroupName $resourceGroup -Location $location

# Create public IP address
$pip = New-AzPublicIpAddress `
          -ResourceGroupName $resourceGroup `
          -Location $location `
          -AllocationMethod Dynamic `
          -Name myPublicIPAddress

# create frontend and backend subnets
$AzpowerpuffFrontendSubnet = New-AzVirtualNetworkSubnetConfig `
                        -Name AzpowerpuffFrontendSubnet `
                        -AddressPrefix 10.0.0.0/24
$AzpowerpuffBackendSubnet = New-AzVirtualNetworkSubnetConfig `
                        -Name AzpowerpuffBackendSubnet `
                        -AddressPrefix 10.0.1.0/24


# Create a virtual network
$vnet = New-AzVirtualNetwork `
        -ResourceGroupName $resourceGroup`
        -Location $location `
        -Name $virtualnetwork `
        -AddressPrefix 10.0.0.0/16 `
        -Subnet $AzpowerpuffFrontendSubnet, $AzpowerpuffBackendSubnet

# Create virtual network interface card
$frontendNic = New-AzNetworkInterface `
                    -ResourceGroupName $resourceGroup `
                    -Location $location `
                    -Name PowerpuffFrontendNIC `
                    -SubnetId $vnet.Subnets[0].Id `
                    -PublicIpAddressId $pip.Id

# Create a front end Virtual machine
$vmConfig = New-AzVMConfig -VMName $virtualMachineName -VMSize 'Standard B2s' | `
  Set-AzVMOperatingSystem -Windows -ComputerName 'powerpuffVm-Web' -Credential $cred | `
  Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2016-Datacenter' -Version latest | Add-AzVMNetworkInterface -Id $nicVMweb.Id

 
 New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

# Create an inbound rule named myFrontendNSGRule to allow icoming web traffic on myFrontendVM 
$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
  -Name myFrontendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

 

# You can limit internal traffic to myBackendVM from only myFrontendVM by creating an NSG for the back-end subnet. 
$nsgBackendRule = New-AzNetworkSecurityRuleConfig `
  -Name myBackendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix 10.0.0.0/24 `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 1433 `
  -Access Allow


# Add a network security group named myFrontendNSG
$nsgFrontend = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRGNetwork `
  -Location EastUS `
  -Name myFrontendNSG `
  -SecurityRules $nsgFrontendRule

# Add a network security group named myBackendNSG
$nsgBackend = New-AzNetworkSecurityGroup `
  -ResourceGroupName myRGNetwork `
  -Location EastUS `
  -Name myBackendNSG `
  -SecurityRules $nsgBackendRule

 
# Add the network security groups to the subnets
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName myRGNetwork `
  -Name myVNet
$frontendSubnet = $vnet.Subnets[0]
$backendSubnet = $vnet.Subnets[1]

$frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name myFrontendSubnet `
  -AddressPrefix $AzpowerpuffFrontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend

$backendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name myBackendSubnet `
  -AddressPrefix $AzpowerpuffBackendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgBackend
Set-AzVirtualNetwork -VirtualNetwork $vnet

 