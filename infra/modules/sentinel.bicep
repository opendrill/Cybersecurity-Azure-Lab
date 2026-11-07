param workspaceName string

resource workspace 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: workspaceName
}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2025-09-01' = {
  scope: workspace
  name: 'default'
}

output sentinelId string = sentinel.id
