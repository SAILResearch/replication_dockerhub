# This script compares the community images with their corresponding official image in terms of their installed libraries without considering their versions. It takes the library data of the images as input, and outputs the cumulutaive shared percentage of the libraries in a csv file. 

if (!require("pacman")) install.packages("pacman")
pacman::p_load(conflicted, here, sqldf, reshape)

container_analysis_result = read.csv(here::here("data","container_analysis_result_for_five_images.csv"), header = TRUE, sep = ",")

container_analysis_result = container_analysis_result#[container_analysis_result$is_auto_installed == "False",]
container_analysis_result$parent_image = as.character(container_analysis_result$parent_image)
container_analysis_result$image = as.character(container_analysis_result$image)

container_analysis_result$value = 1

parent_images = as.character(unique(container_analysis_result$parent_image))



oses = as.character(unique(container_analysis_result$os))

for (f in 1:length(oses)) {
  all_similarity_percentage = data.frame(
    shared_percentage = numeric(),
    image_percentage = numeric(),
    type = character()
  )
  
  current_OS = oses[f]
  for (i in 1:length(parent_images)) {
    current_parent_image = parent_images[i]
    print(paste(current_OS, current_parent_image, i))
    
    current_images = container_analysis_result[which(container_analysis_result$parent_image == current_parent_image 
                                                     & container_analysis_result$os == current_OS),]
    if (length(unique(current_images$image)) > 0) {
      image_vs_lib_data =  cast(current_images, image ~ library)
      image_vs_lib_data[is.na(image_vs_lib_data)] = 0
      rownames(image_vs_lib_data) = image_vs_lib_data[, 1]
      image_vs_lib_data[, 1] = NULL
      image_vs_lib_data[image_vs_lib_data > 1] = 1
      
      official_image_vs_lib_data = image_vs_lib_data[!grepl("/", rownames(image_vs_lib_data)),]
      image_vs_lib_data = image_vs_lib_data[grepl("/", rownames(image_vs_lib_data)),]
      
      shared_lib_percentage = data.frame(shared_percentage = numeric())
      index = 1
      if (nrow(unique(official_image_vs_lib_data)) > 0) {
        for (k in 1:nrow(image_vs_lib_data)) {
          row1 = official_image_vs_lib_data
          row2 = image_vs_lib_data[k, ]
          
          sum_of_rows = row1 + row2
          shared_libs_count = length(sum_of_rows[sum_of_rows == 2])
          
          total_unique_libs = length(sum_of_rows[sum_of_rows > 0])
          
          shared_lib_percentage[index,] = c(round(shared_libs_count / total_unique_libs * 100))
          
          index = index + 1
        }
        
        
        shared_lib_percentage = sqldf(
          "select shared_percentage, count(*) as image_count from shared_lib_percentage group by shared_percentage"
        )
        
        shared_lib_percentage$image_percentage = shared_lib_percentage$image_count /
          (nrow(image_vs_lib_data)) * 100
        shared_lib_percentage$image_count = NULL
        shared_lib_percentage$type = current_parent_image
        
        suplementary_percentage = as.data.frame(setdiff(c(0:100), unique(
          shared_lib_percentage$shared_percentage
        )))
        
        colnames(suplementary_percentage) = c("shared_percentage")
        suplementary_percentage$image_percentage = 0
        suplementary_percentage$type = current_parent_image
        
        all_similarity_percentage = rbind(all_similarity_percentage,
                                          shared_lib_percentage,
                                          suplementary_percentage)
      }
    }
  }
  
  formatted_data = cast(all_similarity_percentage, shared_percentage ~ type, value = 'image_percentage')
  formatted_data[is.na(formatted_data)] = 0
  formatted_data = formatted_data[order(-formatted_data$shared_percentage), ]
  
  colnames = colnames(formatted_data)[2:ncol(formatted_data)]
  
  for (colname in colnames) {
    print(colname)
    formatted_data[, colname] = cumsum(formatted_data[, colname])
  }
  
  # the chart is generated here: https://docs.google.com/spreadsheets/d/1KCxlVMf8xC0Ra3gWr8fDkBBj7zHKsY8-2ze3GWLLFZA/edit?usp=sharing
  write.csv(
    formatted_data,
    here::here("data", paste("shared_library_with_official_image_", current_OS,"_without_version.csv", sep=""))
  )
}
