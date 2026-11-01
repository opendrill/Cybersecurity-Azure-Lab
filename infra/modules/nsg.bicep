param location string
param nsgName string
param rules array = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2026-01-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: rules
  }
}

//returns the id of the created nsg as a variable called nsgId
output nsgId string = nsg.id
