using System.Collections.Generic;

namespace container_diff_json_parser.Models
{
    public class ContainerAnalysis
    {
        public string Image { get; set; }
        public string AnalyzeType { get; set; }
        public List<Package> Analysis { get; set; }
    }
}
