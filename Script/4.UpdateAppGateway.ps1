$ResourceGroupName = "RG-South-india"
$Region = "South India"
$AppGatewayName = "AppGw-DR-SI"
###########################################
# Add Backend Pool

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

$A80_AppURL = $App_A80_Name + ".azurewebsites.net"
$A81_AppURL = $App_A81_Name + ".azurewebsites.net"

# Backend Pool
$A80_BackendPool_Name = "A80-DR-BE"
$A81_BackendPool_Name = "A81-DR-BE"

$A80_BackendPool = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW -Name $A80_BackendPool_Name -BackendIPAddresses $A80_AppURL
$A81_BackendPool = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW -Name $A81_BackendPool_Name -BackendIPAddresses $A81_AppURL

$FPort_443_Name = "Port_443"
$FPort_443 = Add-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGW -Name $FPort_443_Name -Port "443" 

Set-AzApplicationGateway -ApplicationGateway $AppGW

###########################################
# Add SSL and Trusted Certificate

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

# SSL Certificate Configuration
$SSLName = "Trackwizz.com"
$CertPassword = ConvertTo-SecureString -String "Azure123456!" -Force -AsPlainText
$SSLCertificate = Add-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGW -Name $SSLName -CertificateFile "C:\TrackwizDeTestDRAutomation\appgwcert.pfx" -Password $CertPassword

# Trusted Certificate Configuration
$RootCertName = "RootTrackwizz"
$TrustedRootCert = Add-AzApplicationGatewayTrustedRootCertificate -ApplicationGateway $AppGW -Name $RootCertName -CertificateFile "C:\TrackwizDeTestDRAutomation\troot.cer"

Set-AzApplicationGateway -ApplicationGateway $AppGW 


###########################################
# Add Listener

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

$SSLCertificate = Get-AzApplicationGatewaySslCertificate -ApplicationGateway $AppGW -Name $SSLName

$FIPConfig = Get-AzApplicationGatewayFrontendIPConfig -ApplicationGateway $AppGW

$FPort_443 = Get-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGW -Name $FPort_443_Name

# Listener Configuration
$A80_A81_Listener_Name = "API-Listener"
$A80_A81_Listener = Add-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $A80_A81_Listener_Name -Protocol Https `
                    -FrontendIPConfiguration $FIPConfig -FrontendPort $FPort_443 -SSLCertificate $SSLCertificate -HostName "apilab1.trackwizz.com"

Set-AzApplicationGateway -ApplicationGateway $AppGW 


###########################################
# Add Http Settings

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

$TrustedRootCert = Get-AzApplicationGatewayTrustedRootCertificate -ApplicationGateway $AppGW -Name $RootCertName

# HTTP Settings
$A80_Http_Settings_Name = "API-DR-APPA80"
$A81_Http_Settings_Name = "API-DR-APPA81"

$A80_Http_Settings = Add-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $A80_Http_Settings_Name -Port 443 `
                     -Protocol Https -TrustedRootCertificate $TrustedRootCert -HostName $A80_AppURL -CookieBasedAffinity Disabled 
$A81_Http_Settings = Add-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $A81_Http_Settings_Name -Port 443 `
                     -Protocol Https -TrustedRootCertificate $TrustedRootCert -HostName $A81_AppURL -CookieBasedAffinity Disabled 

Set-AzApplicationGateway -ApplicationGateway $AppGW

###########################################
# Add Path based Configs

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

# Backend Pool
$A80_BackendPool = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW -Name $A80_BackendPool_Name 
$A81_BackendPool = Get-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW -Name $A81_BackendPool_Name 

# HTTP Settings
$A80_Http_Settings = Get-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $A80_Http_Settings_Name 
$A81_Http_Settings = Get-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $A81_Http_Settings_Name 

# Path Config
$A80PathConfig = New-AzApplicationGatewayPathRuleConfig -Name "a80path" -Paths "/a80*" -BackendAddressPool $A80_BackendPool -BackendHttpSettings $A80_Http_Settings
$A81PathConfig = New-AzApplicationGatewayPathRuleConfig  -Name "a81path" -Paths "/a81*" -BackendAddressPool $A81_BackendPool -BackendHttpSettings $A81_Http_Settings

$A80_A81_PathConfig_Name = "API_Path_Rules"
$A80_A81_PathConfig = Add-AzApplicationGatewayUrlPathMapConfig -ApplicationGateway $AppGW -Name $A80_A81_PathConfig_Name `
                      -PathRules $A80PathConfig, $A81PathConfig -DefaultBackendAddressPool $A80_BackendPool -DefaultBackendHttpSettings $A80_Http_Settings

Set-AzApplicationGateway -ApplicationGateway $AppGW


###########################################
# Add Routing Rule

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

# Listener Configuration
$A80_A81_Listener = Get-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $A80_A81_Listener_Name

$A80_A81_PathConfig = Get-AzApplicationGatewayUrlPathMapConfig -ApplicationGateway $AppGW -Name $A80_A81_PathConfig_Name

$A80_A81_Rules_Name = "API_Rules"
$A80_A81_Rules = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGW -Name $A80_A81_Rules_Name -RuleType PathBasedRouting -HttpListener $A80_A81_Listener -UrlPathMap $A80_A81_PathConfig

Set-AzApplicationGateway -ApplicationGateway $AppGW

###########################################

# Cleanup Basic Rules

$AppGW = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName

# Backend Pool
$Basic_BackendPool = Remove-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGW  -Name "Basic_BE"

# Listener Configuration
$Basic_Listener = Remove-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name "Basic_Listener"

# HTTP Settings
$Basic_Settings = Remove-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name "Basic_Setting"

$Basic_Rules = Remove-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGW -Name 'Basic_Rules'

$FPort_80 = Remove-AzApplicationGatewayFrontendPort -ApplicationGateway $AppGW -Name "Port_80"

Set-AzApplicationGateway -ApplicationGateway $AppGW