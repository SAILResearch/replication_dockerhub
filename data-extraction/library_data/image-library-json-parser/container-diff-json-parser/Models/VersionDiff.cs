using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace container_diff_json_parser.Models
{
    public class VersionDiff
    {
        public string Package { get; set; }
        public Info Info1 { get; set; }
        public Info Info2 { get; set; }
    }
}
