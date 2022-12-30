using System;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using Azure;
using System.Text.Json;
using RTIndexing.Models;


/*
 Assumption: The Service Bus Message is JSON representation of the Item POCO, that depends on the Search index Schema.
 Change the Search Index Schmea and the POCO to match your needs. Alternatively, you can map the ServiceBus message to 
 POCO. For simplicity, we will assume Service Bus message to match the POCO and index schema.

Service Bus Message sample:
{
    "id" : "1",
    "title" : "title 1",
    "summary" : "summary 1"
}
 
 */

namespace RTIndexing
{
    public class SBToACS
    {

        [FunctionName("SB-to-ACS")]
        public void Run([ServiceBusTrigger("rtsdata", "cogs-indexing", Connection = "servicebusconnection")] ServiceBusReceivedMessage[] messages, ILogger log)
        {
            log.LogInformation($"Number of messages in the batch: {messages.Length}");

            string searchServiceEndPoint = Environment.GetEnvironmentVariable("SearchServiceEndPoint");
            string adminApiKey = Environment.GetEnvironmentVariable("SearchAdminAPIKey");
            string indexName = Environment.GetEnvironmentVariable("IndexName");


            try
            {
                // Create Search Client
                SearchClient searchClient = new SearchClient(new Uri(searchServiceEndPoint), indexName, new AzureKeyCredential(adminApiKey));

                // Create Search Document Batch (ACS = Azure Cognitive Search)
                IndexDocumentsBatch<Item> acsBatch = new IndexDocumentsBatch<Item>();

                // Add service bus mesages to the Search document batch
                foreach (ServiceBusReceivedMessage m in messages)
                {
                    var docToIndex = JsonSerializer.Deserialize<Item>(m.Body.ToString());

                    acsBatch.Actions.Add(IndexDocumentsAction.MergeOrUpload(docToIndex));
                }

                IndexDocumentsResult result = searchClient.IndexDocuments(acsBatch);

                log.LogInformation($"Sent doucment to Cognitive Search for indexing. Number sent for indexing: {acsBatch.Actions.Count}");
            }
            catch ( Exception ex)
            {
                log.LogError($"An Exception occured: {ex.Message}");
                log.LogError($"Exception detail: {ex.InnerException}");
                throw;
            }

        }
    }
}
