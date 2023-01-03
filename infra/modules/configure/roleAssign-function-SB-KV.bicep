@description('The name of the Function App instance')
param functionAppName string

@description('The Service Bus Namespace')
param sbNameSpace string

@description('Specifies the name of the key vault.')
param keyVaultName string


resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
}

var functionId = functionAppInstance.identity.principalId

resource sbInstance 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: sbNameSpace
}

resource keyVaultInstance 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

@description('This is the built-in Azure Service Bus Data Receiver role. ')
resource sbDataReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: sbInstance
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

resource roleAssignmentReceiver 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: sbInstance
  name: guid(resourceGroup().id, functionAppInstance.id, sbDataReceiverRoleDefinition.id)
  properties: {
    roleDefinitionId: sbDataReceiverRoleDefinition.id
    principalId: functionId
    principalType: 'ServicePrincipal'
  }
}


@description('This is the built-in Azure Service Bus Data Sender role. ')
resource sbDataSenderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: sbInstance
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

resource roleAssignmentSender 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: sbInstance
  name: guid(resourceGroup().id, functionAppInstance.id, sbDataSenderRoleDefinition.id)
  properties: {
    roleDefinitionId: sbDataSenderRoleDefinition.id
    principalId: functionId
    principalType: 'ServicePrincipal'
  }
}


@description('This is the built-in Azure Key Vault Secrets User role. ')
resource kvSecretReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: keyVaultInstance
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource roleAssignmentKVReader 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: keyVaultInstance
  name: guid(resourceGroup().id, functionAppInstance.id, kvSecretReaderRoleDefinition.id)
  properties: {
    roleDefinitionId: kvSecretReaderRoleDefinition.id
    principalId: functionId
    principalType: 'ServicePrincipal'
  }
}
