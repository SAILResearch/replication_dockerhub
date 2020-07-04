# Data Collection and Extraction

 All of these data extraction scripts are located in Data-extraction folder.

1. Run the library-data/image-library-extractor java program extracts the libraries for a set of images that should be stored in a csv file.
2. Collect all the extracted libraries json files and put it in a directory and specify the directory in the program library_data/image-library-json-parser which is a C# application and converts the json files into a csv file containing the image and corresponding library information. Note: this program will only work on Windows with .net framework installed.
3. Use required_software_installed_or_not.R script to validate the extracted libraries from step 2. It will extract only the images that contain the target software system.

Executing the above mentioned steps will give the images which installs the target software system by either apt, apk, or rpm package manager along with their installed libraries.


# Research Questions

For answering the research question you need to open the dockerhub-images-paper.Rproj R project inside the r-scripts folder.

PQs. Manually and automatically installed libraries: 
Run the script manually_vs_automatically_installed_libraries.R  which takes the extracted libraries for images from our data collected step 3 and outputs the boxplot and prints a summary of the automatically and manually installed libraries.


RQ1: Differences among Docker images’ libraries: Execute the R script named shared_libs_graph_non-versioned.R which compares images based on their installed libraries and outputs the similarity percentage. The shared_libs_graph_versioned.R does the same comparison, however, it considers the versions of the libraries. Both of these scripts takes the extracted libraries for images generated in 3 in the data collection. To compare the images similarly between the official and community images, run the scripts: official_shared_libs_percentage-versioned.R & official_shared_libs_percentage-non-versioned.R. 


Calculating the number of lib difference from the official image: Run the script number_of_diff_from_official_image_versioned.R & number_of_diff_from_official_image_non_versioned.R which take the library information csv file extracted from step 3 and outputs the boxplots along with their summaries.


Identifying the cluster of images that have the same set of libraries: Run number_of_cluster_versioned.R and number_of_clusters_non_versioned.R to find out the number of clusters that images have based on their installed libraries.


RQ2: Container efficiency: Run the container-efficiency-measure Java program to extract the efficiency information of the images located at Data-extraction\efficiency_data\container-efficiency-measure. It takes the names of the images in a csv file which needs to be evaluated and outputs the efficiency results in text files which need to format by the efficiency-file-parser Java program located at Data-extraction\efficiency_data\efficiency-file-parser. This program outputs the result into a csv format containing the efficiency, wasted bytes data for each image. Using this extracted data run the efficiency_image_analyzer.R which does all the experiments and plot graphs.

RQ3: Security analysis: We refer to ConPan [MSR 2019] to extract the vulnerabilities and get a file similar to data/vulnerabilities.csv 

Run the vulnerability_analysis.R which takes the generated csv file and the image metric data (e.g., number of pulls and stars). It outputs the number of vulnerabilities in each image in a csv file. It also does the correlation analysis between the popularity and security vulnerabilities.

Run security_analysis_official_community.R to compare the security vulnerabilities of official and community images. 

# Discussion

Run the the scripts in the r-scripts/Discussion folder to collect the analyzed data for discussion. Also collect the vulnerability and resource efficiency wilcoxon and spearman test results from the corresponding scripts of resource efficiency, and vulnerability.
