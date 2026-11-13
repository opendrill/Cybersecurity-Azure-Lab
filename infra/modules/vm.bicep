param vmName string
param location string
param subnetId string
param vmSize string
param adminUserName string
param sshPubKey string
param pubIp bool
param installMonitoringAgent bool
param dcrId string

//Optional public IP address.
resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2026-01-01' = if (pubIp) {
  name: '${vmName}-public-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

//create a nic for the vm
resource nic 'Microsoft.Network/networkInterfaces@2026-01-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: pubIp ? {id: publicIpAddress!.id} : null //if pubIp = true give it the id, else give it null.
        }
      } 
    ]
  }
}

//create an Ubuntu server vm with password authentication disabled, ssh only.
resource vm 'Microsoft.Compute/virtualMachines@2026-04-01' = {
  name: vmName
  location: location
  identity: installMonitoringAgent ? { type: 'SystemAssigned' } : null
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUserName}/.ssh/authorized_keys' //needs revision
              keyData: sshPubKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

//assosciating the syslog collection dcr rule.
resource dcrAssosciation 'Microsoft.Insights/dataCollectionRuleAssociations@2024-03-11' = if (installMonitoringAgent) {
  name: '${vmName}-syslog-dcr'
  scope: vm
  properties: {
    dataCollectionRuleId: dcrId
  }
}

//installing defender agent.
resource linuxAgent 'Microsoft.Compute/virtualMachines/extensions@2026-04-01' = if (installMonitoringAgent) {
  parent: vm
  name: '${vmName}-AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.21'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

output vmId string = vm.id
output privateIpAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output publicIpAddress string = pubIp ? publicIpAddress!.properties.ipAddress : '' //if pubIp true output the ip address of the resource, else output blank string.
