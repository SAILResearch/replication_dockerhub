library(sqldf)

container_analysis_result = read.csv(file = "data/container-analysis-results.csv", header = TRUE)

 container_analysis_result = sqldf(
   "select image, library, parent_image from container_analysis_result"
 )

parent_images = unique(container_analysis_result$parent_image)
missing_software = data.frame(official_image = character(), installed = integer(), missing = integer())

valid_images = NULL
count = 0

for (image in parent_images) {
  image_name = as.character(image)
  images = container_analysis_result[(container_analysis_result$parent_image == image_name),]
  installed = images[(grepl(image_name, images$library)), ]
  
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

container_analysis_result = read.csv(file = "data/container-analysis-results.csv", header = TRUE)

x<-container_analysis_result[which(container_analysis_result$image %in% valid_images$image),]
write.csv(x, "data/container_analysis_result_for_five_images.csv", row.names = FALSE)

