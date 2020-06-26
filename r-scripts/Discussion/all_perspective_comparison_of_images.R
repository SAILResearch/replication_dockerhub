if (!require("pacman")) install.packages("pacman")
pacman::p_load(conflicted, here, sqldf, ggplot2, stringr, stats)

container_efficiency_result = read.csv(file = here::here("data","container_efficiency_result.csv"), header =
                                         TRUE, sep = ",")

container_efficiency_result = container_efficiency_result[which(container_efficiency_result$os=="debian"),]
image_detail_with_vulnerabilities = read.csv(file = here::here("data","image_detail_with_vulnerabilities.csv"), header =
                                               TRUE, sep = ",")

images_with_all_perspective = sqldf("select image_detail_with_vulnerabilities.*, container_efficiency_result.efficiency
                          from container_efficiency_result inner join image_detail_with_vulnerabilities 
                                    on container_efficiency_result.image = image_detail_with_vulnerabilities.image")

result = data.frame(software_system = character(), percentage_of_community_images_better = numeric())

images_with_all_perspective$parent_image = as.character(images_with_all_perspective$parent_image)
images_with_all_perspective$image = as.character(images_with_all_perspective$image)

images_with_all_perspective$X = NULL
images_with_all_perspective = unique(images_with_all_perspective)
for (parent_image in unique(images_with_all_perspective$parent_image)) {
  print(parent_image)
  
  current_images = images_with_all_perspective[which(images_with_all_perspective$parent_image == parent_image),]
  community_images = images_with_all_perspective[images_with_all_perspective$parent_image == parent_image & images_with_all_perspective$parent_image != images_with_all_perspective$image, ]
  official_image = images_with_all_perspective[images_with_all_perspective$parent_image == parent_image & images_with_all_perspective$parent_image == images_with_all_perspective$image,]
  
  official_image_efficiency = as.numeric(official_image$efficiency)
  official_image_vuls = as.numeric(official_image$total_vuls)
  
  percentage_of_community_images_better = nrow(community_images[community_images$efficiency > official_image_efficiency &
                                                                community_images$total_vuls < official_image_vuls,])/nrow(community_images)*100
 
  
  download_vs_lib_p_val = as.numeric(cor.test(x=current_images$efficiency, y=current_images$total_vuls, method = 'spearman')$estimate)
  print(download_vs_lib_p_val)
  result = rbind(result, data.frame(software_system = parent_image, 
                                    percentage_of_community_images_better = percentage_of_community_images_better))
  #print(community_images[community_images$efficiency > official_image_efficiency &
  #                         community_images$total_vuls < official_image_vuls,])
  
}

