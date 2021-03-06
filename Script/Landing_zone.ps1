
# Variables
$ResourceGroupName = "rg-photon-poc"
$Location = "Central India"
$subnet1Name = "sn-test"
$subnet1Prefix = "10.180.0.0/24"
$subnet2Name = "GatewaySubnet"
$subnet2Prefix = "10.180.1.0/24"
$subnet3Name   = "sn-qa-server"
$subnet3Prefix =  "10.180.2.0/24"
$subnet4Name   =  "sn-infra-servers"
$subnet4Prefix =  "10.180.3.0/24"
$subnet5Name   =  "sn-idc-dmz"
$subnet5Prefix =  "10.180.4.0/24"
$subnet6Name   =  "sn-prod-server"
$subnet6Prefix =  "10.180.5.0/24"
$subnet7Name   =  "sn-dev-server"
$subnet7Prefix =  "10.180.6.0/24"
$VNETName = "vnet-phtn-dc"
$VnetPrefix = "10.180.0.0/16"
$LocalNetworkGatewayName = "vpn-lgw-prod"
$GatewayIPName = "vpn-vgw-pip-prod"
$VNETGatewayName = "vpn-vgw-prod"
$GatewayIPAddress = "49.204.76.138"     ### Adress IP of VPN device onpremise 
$AddressPrefix = "192.168.0.0/26"      ### Onpremise adress space
$VPNConnectionName = "Azure-OnPremise"
$GatewayConfigName = "vgwipconfig1"
$PSKKey = "admin@12345"
 
#Create or check for existing resource group
	$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
	if(!$resourceGroup)
	{
		Write-Host "Resource group '$resourceGroupName' does not exist.";
		if(!$Location) {
        $Location = Read-Host "resourceGroupLocation";
			}
		Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
		New-AzResourceGroup -Name $resourceGroupName -Location $Location
		}
	else{
		Write-Host "Using existing resource group '$resourceGroupName'";
	}
 
#Create Public IP for VPN
$GatewayPublicIP = New-AzPublicIpAddress -Name $GatewayIPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
 
# Now we can configure your VPN device using public IP from above variable :)
 
# Create VNET and subnets
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $subnet1Prefix
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix $subnet2Prefix
$subnet3 = New-AzVirtualNetworkSubnetConfig -Name $subnet3Name -AddressPrefix $subnet3Prefix
$subnet4 = New-AzVirtualNetworkSubnetConfig -Name $subnet4Name -AddressPrefix $subnet4Prefix
$subnet5 = New-AzVirtualNetworkSubnetConfig -Name $subnet5Name -AddressPrefix $subnet5Prefix
$subnet6 = New-AzVirtualNetworkSubnetConfig -Name $subnet6Name -AddressPrefix $subnet6Prefix
$subnet7 = New-AzVirtualNetworkSubnetConfig -Name $subnet7Name -AddressPrefix $subnet7Prefix

New-AzVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VnetPrefix -Subnet $subnet1, $subnet2, $subnet3, $subnet4, $subnet5, $subnet6, $subnet7
 
#Create the local network gateway
 
New-AzLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -GatewayIpAddress $GatewayIPAddress -AddressPrefix $AddressPrefix
 
#Prepare IP adress gateway configuration
$GatewayPIP = Get-AzPublicIpAddress -Name $GatewayIPName -ResourceGroupName $ResourceGroupName
$vnet = Get-AzVirtualNetwork -Name $VNETName -ResourceGroupName $ResourceGroupName
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnet2Name -VirtualNetwork $vnet
$GatewayIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $GatewayConfigName -SubnetId $subnet.Id -PublicIpAddressId $GatewayPIP.Id
 
#Prepare virtual network gateway
New-AzVirtualNetworkGateway -Name $VNETGatewayName -ResourceGroupName $ResourceGroupName -Location $Location -IpConfigurations $GatewayIPConfig -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1
 
$VNETGateway = Get-AzVirtualNetworkGateway -Name $VNETGatewayName -ResourceGroupName $ResourceGroupName
$LocalNetworkGateway = Get-AzLocalNetworkGateway -Name $LocalNetworkGatewayName -ResourceGroupName $ResourceGroupName
 
#Create VPN connection
New-AzVirtualNetworkGatewayConnection -Name $VPNConnectionName -ResourceGroupName $ResourceGroupName `
-Location $Location -VirtualNetworkGateway1 $VNETGateway -LocalNetworkGateway2 $LocalNetworkGateway `
-ConnectionType IPsec -RoutingWeight 10 -SharedKey $PSKKey