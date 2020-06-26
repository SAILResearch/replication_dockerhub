namespace container_diff_json_parser.Models
{
    public class ContainerDiff
    {
        public string Image1 { get; set; }
        public string Image2 { get; set; }
        public string DiffType { get; set; }
        public Diff Diff { get; set; }
    }
}
