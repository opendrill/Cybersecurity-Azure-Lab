targetScope = 'subscription'
param policyName string
param location string
param policyDefId string
param policyDescription string

resource policy 'Microsoft.Authorization/policyAssignments@2026-07-01' = {
  name: policyName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: policyDefId
    description: policyDescription
    displayName: policyName
    nonComplianceMessages: [
      {
        message: 'Resource is not compliant with policy ${policyName}'
      } 
    ]
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: ['uksouth', 'ukwest']
      }
    }
  }
}

output policyId string = policy.id
