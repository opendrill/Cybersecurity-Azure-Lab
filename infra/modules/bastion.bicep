param bastionName string
param location string
param azureBastionSubnetId string

//Bastion needs a public IP address.
resource publicIpForBastion 'Microsoft.Network/publicIPAddresses@2026-01-01' = {
  name: '${bastionName}-public-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

//create bastion.
resource bastion 'Microsoft.Network/bastionHosts@2026-01-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpForBastion.id
          }
          subnet: {
            id: azureBastionSubnetId
          }
        }
      }
    ]
  }
}
