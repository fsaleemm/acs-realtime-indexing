@description('The Service Bus Namespace')
param nameSpace string = 'sb-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The pricing tier of this Service Bus Namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: nameSpace
  location: location
  sku: {
    capacity: 1
    name: sku
    tier: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    zoneRedundant: false
  }
}


output sbNameSpace string = serviceBusNamespace.name
output sbHostName string = '${serviceBusNamespace.name}.servicebus.windows.net'
output sbEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
