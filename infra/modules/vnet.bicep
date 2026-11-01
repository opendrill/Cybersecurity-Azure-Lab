param location string
param vnetName string
param subnets array = []
param addressSpace string = '10.0.0.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2026-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
    subnets: subnets
  }
}

output vnetId string = vnet.id
//making a dict of all created subnet names and ids. Call with 'moduleName'.outputs.subnetIds.'subnetName'
output subnetIds object = toObject(
  vnet.properties.subnets,
  subnet => subnet.name,
  subnet => subnet.id
)
//output honeynetSubnetId string = vnet.properties.subnets[0].id
//output internalSubnetId string = vnet.properties.subnets[1].id
