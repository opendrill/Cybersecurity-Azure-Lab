//need to write using playbook json as template
param location string
param playbookName string
param nsgName string
param nsgResourceGroup string

var sentinelApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuresentinel')

resource sentinelConn 'Microsoft.Web/connections@2016-06-01' = {
  name: '${playbookName}-sentinel'
  location: location
  kind: 'V1'
  properties: {
    displayName: '${playbookName}-sentinel'
    api: {
      id: sentinelApiId
    }
    parameterValueType: 'Alternative'
  }
}

resource playbook 'Microsoft.Logic/workflows@2019-05-01' = {
  name: playbookName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('../../playbooks/block_ip.json')
    parameters: {
      '$connections': {
        value: {
          azuresentinel: {
            connectionId: sentinelConn.id
            connectionName: sentinelConn.name
            id: sentinelApiId
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
        }
      }
      subscriptionId: { value: subscription().subscriptionId }
      nsgResourceGroup: { value: nsgResourceGroup }
      nsgName: { value: nsgName }
    }
  }
}

output playbookId string = playbook.id
output principalId string = playbook.identity.principalId
