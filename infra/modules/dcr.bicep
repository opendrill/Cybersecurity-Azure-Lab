param location string
param ruleName string
param workspaceId string
param workspaceName string

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
          streams: ['Microsoft-Syslog']
          logLevels: ['Emergency', 'Alert', 'Critical', 'Error', 'Warning', 'Notice', 'Info', 'Debug'] //7 severity levels of syslog. I want every syslog message in auth.log to go to log analytics.
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
        streams: ['Microsoft-Syslog']
        destinations: ['${workspaceName}']
      }
    ]
  }
}

output ruleId string = dcr.id
