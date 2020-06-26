using System.Collections.Generic;

namespace container_diff_json_parser.Models
{
    public class Diff
    {
        public List<Package> Packages1 { get; set; }
        public List<Package> Packages2 { get; set; }
        public List<VersionDiff> InfoDiff { get; set; }
    }
}
