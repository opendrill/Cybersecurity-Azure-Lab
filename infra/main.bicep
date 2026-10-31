targetScope = 'subscription'

@description('Azure region for resources')
@allowed(['uknorth', 'ukeast', 'uksouth', 'ukwest']) //allowed arguments.
param location string = 'uksouth' //defaults to uksouth if no argument provided.

resource rgLab 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-lab'
  location: location
}

//IP address range for the honeynet subnet.
var honeynetPrefix = '10.0.1.0/24'
//defining ACL rules for the NSF for the honeynet subnet.
var honeynetRules = [
  {
    name: 'deny-outbound-traffic'
    properties: {
      priority: 100 //must be a value between 100 and 4096.
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
  {
    name: 'allow-in-ssh'
    properties: {
      priority: 200
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: honeynetPrefix
      destinationPortRange:'22'
    }
  }
    {
    name: 'allow-in-http'
    properties: {
      priority: 300
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: honeynetPrefix
      destinationPortRange:'80'
    }
  }
]
//calling the module to create the honeynet NSG and providing relative parameters.
module nsgHoneynet 'modules/nsg.bicep' = {
  name: 'nsg-honeynet'
  scope: rgLab
  params: {
    location: location
    nsgName: 'nsg-honeynet'
    rules: honeynetRules
  }  
}

//IP address range for the internal subnet.
var internalPrefix = '10.0.2.0/24'
//defining ACL rules for the NSG for the internal subnet.
var internalRules = [
  {
    name: 'deny-in-honeynet-traffic'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: internalPrefix
      destinationPortRange: '*'
    }
  }
]
//calling the module to create the internal NSG and providing relative parameters.
module nsgInternal 'modules/nsg.bicep' = {
  name: 'nsg-internal'
  scope: rgLab
  params: {
    location: location
    nsgName: 'nsg-internal'
    rules: internalRules
  }  
}

//we don't want to tear this down.
resource rgMonitoring 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-monitoring'
  location: location
}
