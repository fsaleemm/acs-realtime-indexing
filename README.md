# Azure Cognitive Search - Near Real-time Indexing Pattern

For most scenarios the [Indexers in Azure Cognitive Search](https://learn.microsoft.com/en-us/azure/search/search-indexer-overview) are suitable for indexing data in Cognitive Search. The indexers run on a schedule and the index is at best updated every 5 minutes. However, there are times where real-time indexing is necessary. This article will document the architecture pattern for near real-time indexing in Azure Cognitive Search.

Additionally, there is a demo of using this pattern to index data in Azure SQL Database in near real-time and make it available for searching in Cognitive Search.

![Near real-time indexing pattern - Azure Cognitive Search](media/s1.png)

The pattern leverages the built-in Triggers and Bindings to capture data changes and queue those changes that are then processed to index using Cognitive Search SDK. Azure Key Vault is used to store secrets such as SQL connection strings and Cognitive Search API key.

The data flow is as follows:
1. Data changes are made to data source (e.g. Azure SQL DB) by applications. Data is added, updated etc.
1. A function is triggered when changes occur, and it queues these changes in Service Bus.
1. A function is triggered when items are queues into the Service Bus topic, and it uses the Cognitive Search SDK to push the changes to the search index.
1. Applications can search for the most updated data.

## Benefits of this Architecture

Below are benefits and potential extension scenarios for this architecture.

1. Integrate backend systems using message broker to decouple services for scalability and reliability. 
1. Allows work to be queued when backend systems are unavailable.
1. Provide load leveling to handle bursts in workloads and broadcast messages to multiple consumers.

In the above architecture, Azure Function App processes the messages by simply indexing the data with Azure Cognitive Search. 
Other potential extensions of this architecture are:

1. The function can be converted to a durable function that orchestrates normalization and correlation of data prior to indexing in Cognitive Search.
1. Instead of a Function App, other consumers can process the messages in Service Bus. Services such as Logic Apps to orchestrate workflows, or Microservices running in Container Apps/AKS to process the workload.
1. An Azure EventGrid could be integrated with Service Bus for cost optimization in cases where rate of SQL database data changes is small or changes occur in bursts.
1. The Service bus could be replaced by other queueing technology such as EventHub and EventGrid.

## Using this pattern with Azure SQL Database

The demo is using the [Azure SQL Trigger and Bindings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus-trigger?tabs=in-process%2Cextensionv5&pivots=programming-language-csharp) for Function app to capture data changes and queue them for indexing in Cognitive Search. At the time of creating this demo, the SQL triggers for Azure function are in preview and as such the functionality may change when this feature becomes GA.

![Near real-time indexing for Azure SQL Database](media/s2.png)

Components:
1. [Azure SQL Database](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview?view=azuresql), ItemDB which simulates customer data that needs real-time indexing.
1. [Azure Function App](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview), contains two functions:
    1. SQL-to-SB function that tracks changes in SQL DB (ItemDB) and queues them to the RTSData topic in Service Bus.
    1. SB-to-ACS function that takes the queued data changes and pushes them to Cognitive Search RTS index.
1. [Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview), is used for queuing changes to decouple the processing of changes from the source system.
1. [Azure Cognitive Search](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search) provides the search capability for the SQL DB (ItemDB) data.
1. [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview) stores the ItemDB connection string and the Cognitive Search Admin API Key.

### Demo Setup

1. Login to your Azure in your terminal.

    ```bash
    az login
    ```

1. To check your subscription.

    ```bash
    az account show
    ```

1. Run the deployment. The deployment will create the resource group "rg-\<Name suffix for resources\>". Make sure you are in the 'acs-realtime-indexing' directory.

    ```bash
    git clone https://github.com/fsaleemm/acs-realtime-indexing.git

    cd acs-realtime-indexing

    az deployment sub create --name "<unique deployment name>" --location "<Your Chosen Location>" --template-file infra/main.bicep --parameters name="<Name suffix for resources>"
    ```

1. When prompted, enter SQL Admin account name and the SQL admin password to setup SQL authentication.

    ![Index Setup](/media/s5.png)

    The following deployments will run:

    ![deployment times](media/s3.png)

### Create "rts" Search Index

Create an index named "rts" with the following fields in the index schema.
* id
* title
* summary
* IsDeleted

Steps:
1. In the search service Overview page, Add index, an embedded editor for specifying an index schema will open.
1. Set Index name: "rts"

    ![Index Setup](/media/s4.png)

### Create Item table in ItemDB

1. Login to the Azure SQL Database (ItemDB) using [Azure Data Studio](https://learn.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver16). You will have to [add your IP to the SQL Server firewall rules.](https://learn.microsoft.com/en-us/azure/azure-sql/database/secure-database-tutorial?view=azuresql#set-up-server-level-firewall-rules)

    Use below connection details:
    ![Index Setup](/media/s6.png)

1. Create Item Table
    ```sql
    CREATE TABLE dbo.Item (
        [id] UNIQUEIDENTIFIER PRIMARY KEY,
        [title] NVARCHAR(200) NOT NULL,
        [summary] NVARCHAR(200) NOT NULL,
        [IsDeleted] BIT NOT NULL
    );
    ```

1. Enable change tracking on ItemDB database and Item table.
    ```sql
    ALTER DATABASE [ItemDB]
    SET CHANGE_TRACKING = ON
    (CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

    ALTER TABLE [dbo].[Item]
    ENABLE CHANGE_TRACKING;
    ```

### Demo Capability

1. Add records to the Item table, and they should appear in search results.

    ```sql
    insert into Item (id, title, summary, IsDeleted) VALUES (NEWID(), 'db title 1', 'db summary 1', 0)
    insert into Item (id, title, summary, IsDeleted) VALUES (NEWID(), 'db title 2', 'db summary 2', 0)
    ```

    ![Index Setup](/media/s7.png)

1. Update a record in the Item table, and changes should be reflected in search results.

    ```sql
    UPDATE Item set title='title 1 updated' where id='<GUID of Document with db title 1>'
    ```

    ![Index Setup](/media/s8.png)

1. Mark as deleted (soft delete) record in Item table, and it should be removed from index.

    ```sql
    UPDATE Item set IsDeleted=1 where id='<GUID of Document with title 1 updated>'
    ```

    ![Index Setup](/media/s9.png)

    Search result with "title 1 updated" is removed.

