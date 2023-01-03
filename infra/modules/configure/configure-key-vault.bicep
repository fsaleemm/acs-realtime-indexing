/* @description('The name of the Function App instance')
param functionAppName string */

@description('The name of the Key Vault')
param keyVaultName string

@description('The name of the Search Service')
param searchServicveName string

@description('The name of the SQL logical server.')
param sqlServerFQDN string

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

/* resource functionAppInstance 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName
} */

resource keyVaultInstance 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource searchServiceInstance 'Microsoft.Search/searchServices@2020-08-01' existing = {
  name: searchServicveName
}

var sqlConnString  = 'Server=tcp:${sqlServerFQDN},1433;Initial Catalog=ItemDB;Persist Security Info=False;User ID=${administratorLogin};Password=${administratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

// Add KV Access Policy
/* resource AppServiceAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: keyVaultInstance
  properties: {
    accessPolicies: [
      {
        objectId: functionAppInstance.identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
        tenantId: functionAppInstance.identity.tenantId
      }
    ]
  }
} */


resource SearchAdminKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVaultInstance
  name: 'SearchAdminAPIKey'
  properties: {
    value: searchServiceInstance.listAdminKeys().primaryKey
  }
}

resource SqlConnectionString 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: keyVaultInstance
  name: 'SqlConnectionString'
  properties: {
    value: sqlConnString
  }
}
