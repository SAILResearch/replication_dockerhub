#This script extract the libraries from the csv file generated from th json parser program and concat the data 
#with the previously collected libraries for the images

library(sqldf)

container_analysis_results_additional = read.csv(file = "~/data/container-analysis-results-additional.csv", header =
                             TRUE, sep = ",")

new_container_analysis_results = sqldf("select image, library, parent_image, lib_with_version, is_auto_installed from container_analysis_results_additional")

container_analysis_result_previous = read.csv(file="~/data/container_analysis_result_for_six_images.csv", header=TRUE, sep=",")


container_analysis_result = rbind(container_analysis_result_previous, new_container_analysis_results)
container_analysis_result = unique(container_analysis_result)

image_counts_by_type = sqldf("select parent_image, count(distinct image) as count from container_analysis_result group by parent_image")

write.csv(container_analysis_result, file="~/data/container_analysis_result_for_six_images.csv", row.names=FALSE)


