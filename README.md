# Azure Cognitive Search - Near Real-time Indexing Pattern

For most scenarios the [Indexers in Azure Cognitive Search](https://learn.microsoft.com/en-us/azure/search/search-indexer-overview) are suitable for indexing data in Cognitive Search. The indexers run on a schedule and the index is at best can be updated every 5 minutes. Howver, there are times where real-time indexing is necessary. This article will document the architecture pattern for near real-time indexing in Azure Cognitive Search.

Additionally, there is a demo of using this pattern to index data in Azure SQL Database in near real-time and make it avaiable for searching in Cognitive Search.

![Near real-time indexing pattern - Azure Cognitive Saerch](media/s1.png)

The pattern leverages the built-in Triggers andd Bindings to capture data changes and queue those changes that are then processed to index using Cognitive Search SDK. Azure Key Vault is used to store secrets such as SQL connection strings and Cognitive Search API key.

The data flow is as follows:
1. Data changes are made to data source (e.g. Azure SQL DB) by applications. Data is added, updated etc.
1. A function is triggered when changes occur, and it queues these changes in Service Bus.
1. A function is triggered when items are queues into the Service Bus topic, and it uses the Cognitive Saerch SDK to push the changes to the search index.
1. Applications can search for the most updated data.

## Using this patter with Azure SQL Database

The demo is using the Azure SQL Trigger and Bindings for Function app to capture data changes and queue them for indexing in Cognitive Saerch.

![Near real-time indexing for Azure SQL Database](media/s2.png)

Components:
1. Azure SQL Database, that simulates customer data that needs real-time indexing.
1. Azure Function App, contains two functions:
    1. SQL-to-SB function that tracks changes in SQL DB and sends to the RTSData topic in Service Bus.
    1. SB-to-ACS function that takes the queued data changes and pushes them to Cognitive Search.
1. Azure Service Bus, is used for queuing changes to decouple the processing of changes from the source system.
1. Azure Cognitive Search provides the search capability for the SQL DB data.

### Demo Setup
TBD

### Demo Capability
TBD