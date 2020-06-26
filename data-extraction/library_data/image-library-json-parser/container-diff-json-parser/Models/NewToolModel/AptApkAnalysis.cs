using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace container_diff_json_parser.Models.NewToolModel
{
    public class AptApkAnalysis
    {
        public string imageId { get; set; }
        public OsRelease osRelease { get; set; }
        public Result[] results { get; set; }
    }

    public class OsRelease
    {
        public string name { get; set; }
        public string version { get; set; }
    }

    public class Result
    {
        public string Image { get; set; }
        public string AnalyzeType { get; set; }
        public Analysis[] Analysis { get; set; }
    }

    public class Analysis
    {
        public string Name { get; set; }
        public string Source { get; set; }
        public string[] Provides { get; set; }
        public string Version { get; set; }
        public bool AutoInstalled { get; set; }
        public int Size { get; set; }
        public Dictionary<string, string> Deps { get; set; }
    }
}
