param workspaceName string
param location string

resource workspace 'Microsoft.OperationalInsights/workspaces@2026-03-01' = {
  name: workspaceName
  location: location
  properties: {
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    //retentionInDays: 7 //will run the vulnerable public server for a week //errors when ran
    sku: {
      name: 'PerGB2018'
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    features: {
      disableLocalAuth: false //enforces Microsoft Entra Id sign in when set to true, I don't have Entra Id configured.
      enableLogAccessUsingOnlyResourcePermissions: false //false means you need permissions to access the whole workspace in order to access any resources inside.
    }
  }
}

//no tables by default, will have to make them here.
resource syslogTable 'Microsoft.OperationalInsights/workspaces/tables@2026-03-01' = {
  parent: workspace
  name: 'Syslog'
  properties: {
    plan: 'Analytics'
  }
}

output workspaceName string = workspace.name
output workspaceId string = workspace.id
