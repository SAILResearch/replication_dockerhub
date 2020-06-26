using System;
using System.Collections.Generic;
using System.IO;
using container_diff_json_parser.Models;
using Newtonsoft.Json;
using System.Linq;
using container_diff_json_parser.Models.NewToolModel;

namespace container_diff_json_parser
{
    class Program
    {
        static void Main(string[] args)
        {
            ParseContainerApkAptFile();
        }

        

        private static void ParseContainerApkAptFile()
        {
            var alreadyAnalyzedImages = new List<string>();

            const string containerDiffBasePath = ""; \\ put the directory of the image folders that contain the output json file from the snyk-docker-analyzer;
            var parentDirectoryInfo = new DirectoryInfo(containerDiffBasePath);

            var parentImageDirectories = parentDirectoryInfo.GetDirectories();
            var outputFilePath = Path.Combine(containerDiffBasePath, "..\\analysis-ouput\\container-analysis-results.csv");
            var csvContent = "parent_image, image, os, os_version, type, library, version, lib_with_version, source, provides, depends_on, is_auto_installed \n";
            File.WriteAllText(outputFilePath, csvContent);

            foreach (var imageDirectory in parentImageDirectories)
            {
                var parentImageFolderName = imageDirectory.Name;
                var parentImageName = parentImageFolderName.Split('-')[3];

                var imageFolders = imageDirectory.GetDirectories().ToList();
                var officialImageFolder = imageFolders.FirstOrDefault(folder => !folder.Name.Contains("."));

                if (officialImageFolder != null)
                    imageFolders.Insert(0, officialImageFolder);

                csvContent = "";
                var validImageCount = 0;

                foreach (var imageFolder in imageFolders)
                {
                    if (alreadyAnalyzedImages.Contains(imageFolder.Name))
                    {
                        continue;
                    }

                    var aptFilePath = Path.Combine(imageFolder.FullName, "apk_apt.txt");
                    string aptApkAnalysis;

                    try
                    {
                        aptApkAnalysis = File.ReadAllText(aptFilePath);
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine(e.Message);
                        continue;
                    }

                    var aptApkAnalysisSplits = aptApkAnalysis.Split(new[] { "Retrieving analyses" }, StringSplitOptions.None);
                    string apkAptAnalysisJson;

                    if (aptApkAnalysisSplits.Length > 1)
                    {
                        apkAptAnalysisJson = aptApkAnalysisSplits[1];
                    }
                    else if (aptApkAnalysis.StartsWith("{"))
                    {
                        apkAptAnalysisJson = aptApkAnalysis;
                    }
                    else
                    {
                        continue;
                    }

                    var apkAptAnalysisObject = JsonConvert.DeserializeObject<AptApkAnalysis>(apkAptAnalysisJson);

                    var imageName = imageFolder.Name;
                    var splitedFolderName = imageFolder.Name.Split('.');

                    if (splitedFolderName.Length > 1)
                    {
                        imageName = splitedFolderName[0] + "/" + string.Join(".", splitedFolderName.Skip(1).ToArray());
                    }

                    var csvLine = parentImageName + "," + imageName + "," + apkAptAnalysisObject.osRelease.name + "," + apkAptAnalysisObject.osRelease.version;

                    foreach (var result in apkAptAnalysisObject.results)
                    {
                        if (result.Analysis.Length == 0) continue;

                        csvLine += "," + result.AnalyzeType;
                        foreach (var analysis in result.Analysis)
                        {
                            if (analysis.Provides == null)
                            {
                                analysis.Provides = new string[] { };
                            }
                            if (analysis.Deps == null)
                            {
                                analysis.Deps = new Dictionary<string, string>();
                            }

                            var newLine = csvLine + "," + analysis.Name + "," + analysis.Version + "," + analysis.Name + "-v-" + analysis.Version + "," + analysis.Source + "," +
                                       string.Join(" | ", analysis.Provides) + "," + string.Join(" | ", analysis.Deps.Keys) + "," + analysis.AutoInstalled + "\n";
                            csvContent += newLine;
                        }
                    }

                    if (!string.IsNullOrEmpty(csvContent) && !string.IsNullOrWhiteSpace(csvContent))
                    {
                        validImageCount++;
                        File.AppendAllText(outputFilePath, csvContent);
                    }

                    csvContent = "";
                    alreadyAnalyzedImages.Add(imageFolder.Name);
                }
            }
        }

    }
}
