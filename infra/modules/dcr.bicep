param location string
param ruleName string
param workspaceId string
param workspaceName string

//Syslog collection
resource dcr 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: ruleName
  location: location
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
        {
          name: 'ssh-auth-syslog'
          facilityNames: ['*'] //e.g. ['auth', 'authpriv'] //the specific logs I want syslog messages from.
          streams: ['Syslog']
          logLevels: ['Emergency', 'Alert', 'Critical', 'Error', 'Warning', 'Notice', 'Info'] //7 severity levels of syslog. I want every syslog message to go to log analytics.
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: workspaceName
          workspaceResourceId: workspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Syslog']
        destinations: ['${workspaceName}']
      }
    ]
  }
}

output ruleId string = dcr.id
