targetScope = 'subscription'
@allowed(['ukwest']) //allowed arguments.
param location string = 'ukwest' //defaults to uksouth if no argument provided. doing west for now since south vmSize is restricted for my subscription.
@description('SSH public key file path for VM admin access')
param sshPubKey string
@description('username of the admin, ssh key must be in this /home/username/.ssh/ directory')
param adminUserName string

resource rgLab 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-lab'
  location: location
}

//IP address range for the honeynet subnet.
var honeynetPrefix = '10.0.0.0/29'
//IP address range for the internal subnet.
var internalPrefix = '10.0.0.8/29'
//bastion subnet must have a /26 subnet mask.
var bastionPrefix = '10.0.0.64/26'

//size of the vm
var vmSize string = 'Standard_D2alds_v7' //cheapest size I could see.

//defining ACL rules for the NSF for the honeynet subnet.
var honeynetRules = [
  {
    name: 'allow-in-ssh'
    properties: {
      priority: 100
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
      priority: 200
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: honeynetPrefix
      destinationPortRange:'80'
    }
  }
    {
    name: 'deny-outbound-traffic'
    properties: {
      priority: 300 //must be a value between 100 and 4096.
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
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

//defining ACL rules for the NSG for the internal subnet.
var internalRules = [
  {
    name: 'deny-in-honeynet'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: internalPrefix
      destinationPortRange: '*'
    }
  }
  {
    name: 'deny-out-honeynet'
    properties: {
      priority: 200
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: internalPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: honeynetPrefix
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

//defining the subnets for the lab vnet.
var vnetLabSubnets = [
    {
    name: 'honeynet'
    properties: {
      addressPrefix: honeynetPrefix
      networkSecurityGroup: {
        id: nsgHoneynet.outputs.nsgId
      }
    }
  }
  {
    name: 'internal'
    properties: {
      addressPrefix: internalPrefix
      networkSecurityGroup: {
        id: nsgInternal.outputs.nsgId
      }
    }
  }
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionPrefix
    }
  }
]
//call the module to create lab vnet and subnets.
module vnetLab 'modules/vnet.bicep' = {
  name: 'vnet-lab'
  scope: rgLab
  params: {
    vnetName: 'vnet-lab'
    location: location
    subnets: vnetLabSubnets
  }
}

//call the module to create a canary vm for the internal subnet.
module vmCanary 'modules/vm.bicep' = {
  name: 'vm-canary'
  scope:rgLab
  params: {
    vmName: 'vm-canary'
    location: location
    subnetId: vnetLab.outputs.subnetIds.internal
    vmSize: vmSize
    adminUserName: adminUserName
    sshPubKey: sshPubKey
  }
}

//we don't want to tear this down.
resource rgMonitoring 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-monitoring'
  location: location
}
