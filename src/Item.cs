using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Models;


namespace RTIndexing.Models
{
    public partial class Item
    {
        [SimpleField(IsKey = true, IsFilterable = true)]
        [JsonPropertyName("id")]
        public string Id { get; set; }

        [SearchableField(AnalyzerName = LexicalAnalyzerName.Values.EnLucene)]
        [JsonPropertyName("title")]
        public string Title { get; set; }

        [SearchableField(AnalyzerName = LexicalAnalyzerName.Values.EnLucene)]
        [JsonPropertyName("summary")]
        public string Summary { get; set; }

        public bool IsDeleted { get; set; }


    }
}
