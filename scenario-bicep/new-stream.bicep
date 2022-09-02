@description('Name of the existing Azure Synapse workspace')
param parentWorkspace string

@description('The stream name used to generate the event hub, event hub namespace and Synapse spark pool')
param streamName string

@description('Resource group name used during deployment')
param location string = resourceGroup().location


@description('Pricing tier for event hub namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param eventHubSku string = 'Standard'

var eventHubNamespaceName = '${streamName}ns'
var eventHubName = streamName

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubNamespaceName
  location: location
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  parent: eventHubNamespace
  name: eventHubName
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
  }
}


resource synapseWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' existing = {
  name: parentWorkspace
}

resource synapseSettings 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  name: '${streamName}SP'
  location: location
  parent: synapseWorkspace
  properties:{
    
    nodeSizeFamily: 'MemoryOptimized'
    nodeSize: 'Small'
    autoScale: {
      enabled:false
    }
    nodeCount: 3
    dynamicExecutorAllocation:{
      enabled:false
    }
    autoPause:{
      delayInMinutes: 15
      enabled:false
    }
    sparkVersion: '3.2'

  }
}
