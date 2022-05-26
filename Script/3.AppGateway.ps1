$ResourceGroupName = "RG-South-india"
$Region = "South India"
$AppGatewayName = "AppGw-DR-SI000"

# VNet Configuration
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name "Saas-DR-SI-Vnet"
$AGSubNet = Get-AzVirtualNetworkSubnetConfig -Name "sn-applicationgateway" -VirtualNetwork $VNet
$GIPConfig = New-AzApplicationGatewayIPConfiguration -Name "GatewayConfig" -Subnet $AGSubNet

# Public IP Configuration
$PublicIP = New-AzPublicIpAddress -Name "AGW-DR-SI-PIP1" -ResourceGroupName $ResourceGroupName -AllocationMethod Static -Sku Standard -Location $Region -Force
$FIPConfig = New-AzApplicationGatewayFrontendIPConfig -Name "AGW-DR-SI-PIP" -PublicIPAddress $PublicIP
$FPort_80 = New-AzApplicationGatewayFrontendPort -Name "Port_80" -Port "80"



# Backend Pool
$Basic_BackendPool = New-AzApplicationGatewayBackendAddressPool -Name "Basic_BE"

# Listener Configuration
$Basic_Listener = New-AzApplicationGatewayHttpListener -Name "Basic_Listener" -Protocol Http -FrontendIPConfiguration $FIPConfig -FrontendPort $FPort_80



# HTTP Settings
$Basic_Settings = New-AzApplicationGatewayBackendHttpSetting -Name "Basic_Setting"  -Port 80 -Protocol Http -CookieBasedAffinity Disabled 
$Basic_Rules = New-AzApplicationGatewayRequestRoutingRule -Name 'Basic_Rules' -RuleType Basic -HttpListener $Basic_Listener -BackendAddressPool $Basic_BackendPool -BackendHttpSettings $Basic_Settings

#Create Application Gateway

$AG_SKU = New-AzApplicationGatewaySku -Name WAF_v2 -Tier WAF_v2  -Capacity 2

New-AzApplicationGateway `
  -Name $AppGatewayName `
  -ResourceGroupName $ResourceGroupName `
  -Location $Region `
  -BackendAddressPools $Basic_BackendPool `
  -BackendHttpSettingsCollection $Basic_Settings `
  -FrontendIpConfigurations $FIPConfig `
  -GatewayIpConfigurations $GIPConfig `
  -FrontendPorts $FPort_80 `
  -HttpListeners $Basic_Listener `
  -RequestRoutingRules $Basic_Rules `
  -Sku $AG_SKU `
  -Verbose
