@description('The Service Bus Namespace')
param nameSpace string

resource sbInstance 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: nameSpace
}

resource rtsdataTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  name: 'rtsdata'
  parent: sbInstance
  properties: {
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    defaultMessageTimeToLive: 'P14D'
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: true
    enableExpress: false
    enablePartitioning: false
    maxMessageSizeInKilobytes: 256
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    status: 'Active'
    supportOrdering: true
  }
}

resource cogsIindexingSsubscroption 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  name: 'cogs-indexing'
  parent: rtsdataTopic
  properties: {
    autoDeleteOnIdle: 'P14D'
    deadLetteringOnFilterEvaluationExceptions: false
    deadLetteringOnMessageExpiration: false
    defaultMessageTimeToLive: 'P14D'
    enableBatchedOperations: true
    isClientAffine: false
    lockDuration: 'PT30S'
    maxDeliveryCount: 10
    requiresSession: false
    status: 'Active'
  }
}
