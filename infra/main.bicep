targetScope = 'subscription'

@allowed(['ukwest']) //allowed arguments.
param location string = 'ukwest' //defaults to uksouth if no argument provided. doing west for now since south vmSize is restricted for my subscription.

@description('SSH public key file path for VM admin access')
param sshPubKey string

@description('username of the admin, ssh key must be in this /home/username/.ssh/ directory')
param adminUserName string

//creating the resource group.
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

//size of the vms
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
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: honeynetPrefix
      destinationPortRange:'22'
    }
  }
  {
    name: 'allow-out-internet'
    properties: {
      priority: 200
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '*'
    }
  }
  {
    name: 'deny-outbound-traffic-internal'
    properties: {
      priority: 300
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: internalPrefix
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
    name: 'allow-in-ssh-bastion'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: bastionPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: internalPrefix
      destinationPortRange:'22'
    }
  }
  {
    name: 'allow-out-internet'
    properties: {
      priority: 200
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '*'
    }
  }
  {
    name: 'deny-in-honeynet'
    properties: {
      priority: 300
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: honeynetPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
  {
    name: 'deny-out-honeynet'
    properties: {
      priority: 400
      direction: 'Outbound'
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: '*'
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

//defining ACL rules for the NSG for the AzureBastionSubnet.
//NSG rules need more work.
var AzureBastionSubnetRules = [
  {
    name: 'AllowHttpsInbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
    {
    name: 'AllowGatewayManagerInbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 200
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'GatewayManager'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
    {
    name: 'AllowBastionHostCommunication' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 300
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: ['8080', '5701']
    }
  }
  {
    name: 'AllowAzureLoadBalancerInbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 400
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'AzureLoadBalancer'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowSshRdpOutbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 500
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: ['22', '3389']
    }
  }
  {
    name: 'AllowAzureCloudOutbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 600
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'AzureCloud'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowBastionCommunication' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 700
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: ['8080', '5701']
    }
  }
   {
    name: 'AllowHttpOutbound' //copied from https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg?tabs=portal
    properties: {
      priority: 800
      direction: 'Outbound'
      access: 'Allow'
      protocol: '*'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '80'
    }
  } 
]
//calling the module to create the AzureBastionSubnet NSG.
module nsgAzureBastionSubnet 'modules/nsg.bicep' = {
  name: 'nsg-AzureBastionSubnet'
  scope: rgLab
  params: {
    location: location
    nsgName: 'nsg-AzureBastionSubnet'
    rules: AzureBastionSubnetRules
  }
}

//defining the subnets for the lab vnet.
var vnetLabSubnets = [
    {
    name: 'honeynet'
    properties: {
      defaultOutboundAccess: true
      addressPrefix: honeynetPrefix
      networkSecurityGroup: {
        id: nsgHoneynet.outputs.nsgId
      }
    }
  }
  {
    name: 'internal'
    properties: {
      defaultOutboundAccess: false
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
      networkSecurityGroup: {
        id: nsgAzureBastionSubnet.outputs.nsgId
      }
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

//call the module to create a canary vm on the internal subnet.
/*
module vmCanary 'modules/vm.bicep' = {
  name: 'vm-canary'
  scope: rgLab
  params: {
    vmName: 'vm-canary'
    location: location
    subnetId: vnetLab.outputs.subnetIds.internal
    vmSize: vmSize
    adminUserName: adminUserName
    sshPubKey: sshPubKey
    pubIp: false
  }
}
*/

module sshHoneypot 'modules/vm.bicep' = {
  name: 'vm-ssh'
  scope: rgLab
  params: {
    vmName: 'vm-ssh'
    location: location
    subnetId: vnetLab.outputs.subnetIds.honeynet
    vmSize: vmSize
    adminUserName: adminUserName
    sshPubKey: sshPubKey
    pubIp: false //change to true later
  }
}

//call the module to create a bastion in the bastion subnet.
module bastion 'modules/bastion.bicep' = {
  name: 'bastion'
  scope: rgLab
  params: {
    bastionName: 'bastion'
    location: location
    azureBastionSubnetId: vnetLab.outputs.subnetIds.AzureBastionSubnet
  }
}

//we don't want to tear this down.
resource rgMonitoring 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: 'rg-monitoring'
  location: location
}
