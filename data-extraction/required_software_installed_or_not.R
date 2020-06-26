library(sqldf)

container_analysis_result = read.csv(file = "data/container-analysis-results-sample.csv", header = TRUE)
# container_analysis_result$type = "lib"

 container_analysis_result = sqldf(
   "select image, library, parent_image from container_analysis_result"
 )

# 
# images_commands = read.csv(file = "~/data/images_with_splitted_commands.csv")
# images_commands$type = "command"

# commmands_library_combined = unique(rbind(container_analysis_result, images_commands))


#commmands_library_combined = commmands_library_combined[commmands_library_combined$parent_image != 'tomcat',]


# commmands_library_combined = sqldf("select parent_image, image, GROUP_CONCAT(library) as libs from commmands_library_combined group by parent_image, image, type")

parent_images = unique(container_analysis_result$parent_image)
missing_software = data.frame(official_image = character(), installed = integer(), missing = integer())

valid_images = NULL
count = 0

for (image in parent_images) {
  image_name = as.character(image)
  images = container_analysis_result[(container_analysis_result$parent_image == image_name),]
  installed = images[(grepl(image_name, images$library)), ]
  #installed = images[which(images$library == image_name), ]
  
  # images_with_types = sqldf("select image, parent_image, GROUP_CONCAT(distinct type) as types from installed group by image, parent_image")
  # installed_in_command_only = images_with_types[ images_with_types$types=="command",]
  #   
  # current_images_command = images_commands[(images_commands$parent_image == image_name),]
  # installed_in_command = current_images_command[(grepl(image_name, current_images_command$library)), ]
  
  
  if(count == 0){
    count = count +1
    valid_images = installed
  }else{
    valid_images = rbind(valid_images, installed)
  }
  
  missing_software = rbind(missing_software,
                           data.frame(
                             official_image = image_name,
                             installed = length(unique(installed$image)),
                             missing = length(unique(images$image)) - length(unique(installed$image))
                           ))
}

valid_images = sqldf("select image, parent_image from valid_images group by image, parent_image")

write.csv(valid_images, "data/valid_images.csv", row.names = FALSE)

container_analysis_result = read.csv(file = "data/container-analysis-results-sample.csv", header = TRUE)

x<-container_analysis_result[which(container_analysis_result$image %in% valid_images$image),]
write.csv(x, "data/container_analysis_result_for_five_images.csv", row.names = FALSE)

