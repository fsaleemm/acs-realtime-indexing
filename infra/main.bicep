targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix/Suffix for all resources, i.e. {name}storage, rg-{name}')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
}


module sql './modules/sql.bicep' = {
  name: '${rg.name}-sql'
  scope: rg
  params: {
    serverName: 'sql-${toLower(name)}'
    sqlDBName: 'ItemDB'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    location: rg.location
  }
}

module acsearch './modules/acsearch.bicep' = {
  name: '${rg.name}-acsearch'
  scope: rg
  params: {
    name: 'acs-${toLower(name)}'
    location: rg.location
  }
}

module servicebus './modules/service-bus.bicep' = {
  name: '${rg.name}-servicebus'
  scope: rg
  params: {
    nameSpace: 'sb-${toLower(name)}'
    sku: 'Standard'
    location: rg.location
  }
}

module function './modules/function.bicep' = {
  name: '${rg.name}-function'
  scope: rg
  params: {
    appName: 'func-${toLower(name)}'
    location: rg.location
    appInsightsLocation: rg.location
  }
}

module keyvault './modules/keyvault.bicep' = {
  name: '${rg.name}-keyvault'
  scope: rg
  params: {
    keyVaultName: 'kv-${toLower(name)}'
    location: rg.location
  }
}

module roleAssignmentFcuntionSB './modules/configure/roleAssign-function-SB-KV.bicep' = {
  name: '${rg.name}-roleAssignmentFunctionSB'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    sbNameSpace: servicebus.outputs.sbNameSpace
    keyVaultName: keyvault.outputs.keyVaultName
  }
  dependsOn: [
    function
    servicebus
    keyvault
  ]
}

module configurFunctionAppSettings './modules/configure/configure-function.bicep' = {
  name: '${rg.name}-configureFunction'
  scope: rg
  params: {
    functionAppName: function.outputs.functionAppName
    searchServicveUrl: acsearch.outputs.searchServiceUrl
    sbHostName: servicebus.outputs.sbHostName
    keyVaultName: keyvault.outputs.keyVaultName
  }
  dependsOn: [
    function
    servicebus
    acsearch
    keyvault
  ]
}

module configurKeyVault './modules/configure/configure-key-vault.bicep' = {
  name: '${rg.name}-configureKV'
  scope: rg
  params: {
    searchServicveName: acsearch.outputs.searchServiceName
    keyVaultName: keyvault.outputs.keyVaultName
    sqlServerFQDN: sql.outputs.SqlServerNameFQDN
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  dependsOn: [
    acsearch
    keyvault
    sql
  ] 
}

module configurServiceBus './modules/configure/configure-service-bus.bicep' = {
  name: '${rg.name}-configureSB'
  scope: rg
  params: {
    nameSpace: servicebus.outputs.sbNameSpace
  }
  dependsOn: [
    servicebus
  ] 
}

