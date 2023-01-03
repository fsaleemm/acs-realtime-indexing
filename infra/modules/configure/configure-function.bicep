@description('The name of the Function App instance')
param functionAppName string

@description('The name of the Search Service')
param searchServicveUrl string

@description('The name of the Key Vault')
param keyVaultName string

@description('The Service Bus Namespace Host Name')
param sbHostName string

param repositoryUrl string = 'https://github.com/fsaleemm/acs-realtime-indexing.git'
param branch string = 'feature/deploy'

resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

var customAppSettings = {
  SearchServiceEndPoint: searchServicveUrl
  SearchAdminAPIKey: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=SearchAdminAPIKey)'
  IndexName: 'rts'
  servicebusconnection__fullyQualifiedNamespace: sbHostName
  SqlConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=SqlConnectionString)'
}

var currentAppSettings = list('${functionAppInstance.id}/config/appsettings', '2021-02-01').properties

module configurFunctionAppSettings './append-function-appsettings.bicep' = {
  name: '${functionAppName}-appendsettings'
  params: {
    functionAppName: functionAppName
    currentAppSettings: currentAppSettings
    customAppSettings: customAppSettings
  }
}

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${functionAppInstance.name}/web'
  properties: {
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
  dependsOn: [
    configurFunctionAppSettings
  ]
}
