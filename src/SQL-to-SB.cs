using System.Collections.Generic;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Sql;
using Microsoft.Extensions.Logging;
using Azure.Messaging.ServiceBus;
using System.Text.Json;
using System.Threading.Tasks;
using System;
using RTIndexing.Models;

namespace RTIndexing
{
    public class SQLToSB
    {
        [FunctionName("SQL-to-SB")]
        public static async Task Run(
            [SqlTrigger("[dbo].[Item]", ConnectionStringSetting = "SqlConnectionString")] IReadOnlyList<SqlChange<Item>> changes,
            [ServiceBus("rtsdata", Connection = "servicebusconnection")] ServiceBusSender sender,
            ILogger log)
        {

            log.LogInformation($"Number of changes: {changes.Count}");

            try
            {
                ServiceBusMessageBatch messageBatch = await sender.CreateMessageBatchAsync();

                foreach (SqlChange<Item> change in changes)
                {
                    Item item = change.Item;

                    if (!messageBatch.TryAddMessage(new ServiceBusMessage(JsonSerializer.Serialize<Item>(item))))
                    {
                        // if it is too large for the batch
                        log.LogError($"The message is too large to fit in the batch. Id: {change.Item.Id}");
                    }
                }

                await sender.SendMessagesAsync(messageBatch);

                log.LogInformation($"Sent changes to Service Bus. Number of changes sent: {messageBatch.Count}");
            }
            catch (Exception ex)
            {
                log.LogError($"An Exception occured: {ex.Message}");
                log.LogError($"Exception detail: {ex.InnerException}");
                throw;
            }
        }
    }
}