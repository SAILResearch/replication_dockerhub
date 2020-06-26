library(data.table)
library(dplyr)
library(rlist)
library(flexclust)
library(usedist)
library(cluster)




container_analysis_result = read.csv(file = "data/container_analysis_result_for_five_images.csv", header =
                                       TRUE, sep = ",")
container_analysis_result = container_analysis_result #[container_analysis_result$is_auto_installed == "False",]
container_analysis_result$val = 1

parent_images = as.character(unique(container_analysis_result$parent_image))

#oses = as.character(unique(container_analysis_result$os))
oses <- c("debian", "centos", "ubuntu", "alpine")
for (f in 1:length(oses)) {
  current_os = oses[f]
  cluster_result = data.frame(cluster=numeric(), count=numeric(), names=character(), parent_image=character())
  
  custom_distance <- function (v1, v2)
  {
    return (sum(abs(v1 - v2)))
  }
  
  calculate_diff = function (diff, max, parent_image) {
    number_of_clusters = 2
    while (number_of_clusters < max) {
      # print(number_of_clusters)
      cluster = pam(dist_matrix, number_of_clusters, diss = TRUE)
      
      cluster_data_frame = as.data.frame(cluster$clustering)
      colnames(cluster_data_frame) = c("cluster")
      
      cluster_info = as.data.frame(cluster$clusinfo)
      
      if (max(cluster_info$diameter) > diff) {
        number_of_clusters = number_of_clusters + 1
      } else{
        break
      }
    }
    
    cluster_data_frame$image_name = rownames(cluster_data_frame)
    
    clusters = sqldf("select cluster, count(*) as count, GROUP_CONCAT(image_name) as names from cluster_data_frame group by cluster")
    clusters = clusters[clusters$count > 1,]
    clusters$parent_image = parent_image
    
    return (clusters)
  }
  data_to_be_plotted = data.frame(parentImage = character(),
                                  type = character(),
                                  value = numeric())
  
  for (i in 1:length(parent_images)) {
    current_parent_image = parent_images[i]
    #print(cat(current_parent_image, i))
    current_images = container_analysis_result[which(container_analysis_result$parent_image == current_parent_image
                                                     & container_analysis_result$os == current_os),]
    if(length(unique(current_images$image)) > 0) {
      image_vs_lib_data =  cast(current_images, image ~ library)
      image_vs_lib_data[is.na(image_vs_lib_data)] = 0
      rownames(image_vs_lib_data) = image_vs_lib_data[, 1]
      image_vs_lib_data[, 1] = NULL
      image_vs_lib_data[image_vs_lib_data > 1] = 1
      
      image_matrix = as.matrix(image_vs_lib_data)
      dist_matrix = dist_make(image_matrix, custom_distance, "custom distance")
      
      parentImageName = current_parent_image
      no_diff = calculate_diff(0, nrow(image_vs_lib_data), current_parent_image)
      
      cluster_result = rbind(cluster_result, no_diff)
      
      row1 = data.frame(parentImage = parentImageName,
                        type = "no diff",
                        nbre_clusters = nrow(no_diff),
                        number_images = sum(no_diff$count), 
                        total_images = nrow(image_vs_lib_data),
                        percentage_images = 100*sum(no_diff$count)/nrow(image_vs_lib_data))
      
      data_to_be_plotted = rbind(data_to_be_plotted, row1)
    }
  }
  
  print(current_os)
  print(data_to_be_plotted)
  print(summary(data_to_be_plotted))
  print("-----------------------")
  #ggplot(data = data_to_be_plotted, aes(
  #  x = reorder(parentImage, -value),
  #  y = value,
  #  #fill = 1,
  #  width = 0.7
  #)) +
  #  geom_bar(stat = "identity", position = position_dodge(), fill="steelblue") +
  #  theme_minimal() +
  #  xlab("Image types") +
  #  ylab("# of clusters")
  
}
