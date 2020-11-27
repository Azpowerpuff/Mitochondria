New-AzResourceGroup -ResourceGroupName ForbesResourceGroup -Location WestEurope

 


$frontendSubnet = New-AzVirtualNetworkSubnetConfig `
  -Name ForbesFrontendSubnet `
  -AddressPrefix 192.16.0.0/27

 


  $backendSubnet = New-AzVirtualNetworkSubnetConfig `
  -Name ForbesBackendSubnet `
  -AddressPrefix 192.16.0.32/27

 


  $vnet = New-AzVirtualNetwork `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -Name Forbes-VNet `
  -AddressPrefix 192.16.0.0/24 `
  -Subnet $frontendSubnet, $backendSubnet

 


  $pip = New-AzPublicIpAddress `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -AllocationMethod Static `
  -Name ForbesPublicIPAddress

 

 
$frontendNic = New-AzNetworkInterface `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -Name ForbesFrontendNIC `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id

 


  $cred = Get-Credential
  
  

 

  New-AzVM `
   -Credential $cred `
   -Name FrontendVM `
   -ResourceGroupName ForbesResourceGroup `
   -Location WestEurope `
   -Size Standard_B2s `
   -SubnetName ForbesFrontendSubnet `
   -VirtualNetworkName Forbes-VNet

 


# $vmConfig = New-AzVMConfig `
# -VMName "FrontendVM" `
# -VMSize "Standard_B2s" | `
# Set-AzVMOperatingSystem `
# -Linux `
# -ComputerName "cmptVM" `
# -Credential $cred `
 
# Set-AzVMSourceImage `
# -PublisherName "Canonical" `
# -Offer "UbuntuServer" `
# -Skus "16.04-LTS" `
# -Version "latest" | `
# Add-AzVMNetworkInterface `
# -Id $frontendNic.Id
 
 $vmConfig = New-AzVMConfig -VMName 'FrontendVM' -VMSize 'Standard_B2s' | `
 Set-AzVMOperatingSystem -Linux -ComputerName 'cmptvM' -Credential $cred | `
 Set-AzVMSourceImage -PublisherName 'Canonical' -Offer 'UbuntuServer' `
 -Skus '16.04-LTS' -Version latest | Add-AzVMNetworkInterface -Id $frontendNic.Id
 
 echo "Virtual machine created"

 

 

$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
  -Name ForbesFrontendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange (3389) `
  -Access Allow

 


  $nsgBackendRule = New-AzNetworkSecurityRuleConfig `
  -Name ForbesBackendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix 192.16.0.0/27 `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 1433 `
  -Access Allow

 


  $nsgFrontend = New-AzNetworkSecurityGroup `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -Name ForbesFrontendNSG `
  -SecurityRules $nsgFrontendRule

 


  $nsgBackend = New-AzNetworkSecurityGroup `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -Name ForbesBackendNSG `
  -SecurityRules $nsgBackendRule

 


$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName ForbesResourceGroup `
  -Name Forbes-VNet
$frontendSubnet = $vnet.Subnets[0]
$backendSubnet = $vnet.Subnets[1]
$frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name ForbesFrontendSubnet `
  -AddressPrefix $frontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend
$backendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name ForbesBackendSubnet `
  -AddressPrefix $backendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgBackend
Set-AzVirtualNetwork -VirtualNetwork $vnet

 


$backendNic = New-AzNetworkInterface `
  -ResourceGroupName ForbesResourceGroup `
  -Location WestEurope `
  -Name ForbesBackendNic `
  -SubnetId $vnet.Subnets[1].Id

 

 
  $cred = Get-Credential

 

    New-AzVM `
   -Credential $cred `
   -Name ForbesBackendVM `
   -ResourceGroupName ForbesResourceGroup `
   -Location WestEurope `
   -SubnetName ForbesBackendSubnet `
   -VirtualNetworkName Forbes-VNet

 

 


 
 New-AzVMConfig -VMName 'ForbesBackendVM' -VMSize 'Standard_B2s' | `
 Set-AzVMOperatingSystem -Windows -ComputerName 'forbesVM' -Credential $cred | `
 Set-AzVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
 -Skus '2016-Datercenter' -Version latest | Add-AzVMNetworkInterface -Id $frontendNic.Id

 

 echo "Back Virtual machine created"