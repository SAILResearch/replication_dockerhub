if (!require("pacman")) install.packages("pacman")
pacman::p_load(conflicted, here, sqldf, reshape)

container_analysis_result = read.csv(here::here("data","container_analysis_result_for_five_images.csv"), header = TRUE, sep = ",")

container_analysis_result$parent_image = as.character(container_analysis_result$parent_image)
container_analysis_result$image = as.character(container_analysis_result$image)

container_analysis_result$value = 1

parent_images = as.character(unique(container_analysis_result$parent_image))
diff_count_data = data.frame(parent_image = character(),
                             change_count = numeric(),
                             percentage=numeric(),
                             type = character())

for (i in 1:length(parent_images)) {
  current_parent_image = parent_images[i]
  print(cat(current_parent_image, i))
  
  current_images = container_analysis_result[container_analysis_result$parent_image == current_parent_image, ]
  
  image_vs_lib_data =  cast(current_images, image ~ lib_with_version)
  image_vs_lib_data[is.na(image_vs_lib_data)] = 0
  rownames(image_vs_lib_data) = image_vs_lib_data[, 1]
  image_vs_lib_data[, 1] = NULL
  image_vs_lib_data[image_vs_lib_data > 1] = 1
  
  official_image_vs_lib_data = image_vs_lib_data[!grepl("/", rownames(image_vs_lib_data)), ]
  image_vs_lib_data = image_vs_lib_data[grepl("/", rownames(image_vs_lib_data)), ]
  
  shared_lib_percentage = data.frame(shared_percentage = numeric())
  index = 1
  
  for (k in 1:nrow(image_vs_lib_data)) {
    row1 = official_image_vs_lib_data
    row2 = image_vs_lib_data[k,]
    
    diff_of_rows = row2 - row1
    
    added_lib_count = length(diff_of_rows[diff_of_rows > 0])
    removed_lib_count = length(diff_of_rows[diff_of_rows < 0])
    
    diff_count_data = rbind(
      diff_count_data,
      data.frame(
        parent_image = current_parent_image,
        change_count = added_lib_count,
        percentage = added_lib_count/ncol(row1[,row1 > 0])*100,
        type = "Additional libraries"
      )
    )
    
    diff_count_data = rbind(
      diff_count_data,
      data.frame(
        parent_image = current_parent_image,
        change_count = removed_lib_count,
        percentage = removed_lib_count/ncol(row1[,row1 > 0])*100,
        type = "Missing libraries"
      )
    )
  }
}

ggplot(diff_count_data, aes(x = parent_image, y = change_count, fill = type)) +
  geom_boxplot() +
  xlab("") +
  ylab("# of libraries")+
  ylim(0,500)



library(plyr)
summary_for_added_libs= ddply(diff_count_data[diff_count_data$type == "Additional libraries",], .(parent_image), summarise, avg=mean(change_count), median=median(change_count), 
                q1=quantile(change_count, 0.25), q3=quantile(change_count, 0.75), min=min(change_count), max=max(change_count))
summary_for_added_libs$type = "Additional libraries"

summary_for_removed_libs = ddply(diff_count_data[diff_count_data$type == "Missing libraries",], .(parent_image), summarise, avg=mean(change_count), median=median(change_count),
                         q1=quantile(change_count, 0.25), q3=quantile(change_count, 0.75), min=min(change_count), max=max(change_count))
summary_for_removed_libs$type = "Missing libraries"

summaries = rbind(summary_for_added_libs
                    , summary_for_removed_libs
                  )
summaries = summaries[order(summaries$parent_image, summaries$type),]
summaries[, c(1, 8, 6, 2, 3, 4, 5, 7)]


################## pecentage

#diff_count_data[diff_count_data$percentage == 0,]$percentage = 1 # handling zero values for log scale coversion 
ggplot(diff_count_data, aes(x = parent_image, y = percentage, fill = type)) +
  geom_boxplot() +
  xlab("") +
  ylab("% of libraries")+
  theme(legend.title=element_blank(), legend.position="top")+
  scale_fill_manual(values = c("#08BAC4", "#FB756F"))+
  scale_y_continuous(trans='log1p')


library(plyr)
summary_for_added_libs= ddply(diff_count_data[diff_count_data$type == "Additional libraries",], .(parent_image), summarise, avg=mean(percentage), median=median(percentage), 
                              q1=quantile(percentage, 0.25), q3=quantile(percentage, 0.75), min=min(percentage), max=max(percentage))
summary_for_added_libs$type = "Additional libraries"

summary_for_removed_libs = ddply(diff_count_data[diff_count_data$type == "Missing libraries",], .(parent_image), summarise, avg=mean(percentage), median=median(percentage),
                                 q1=quantile(percentage, 0.25), q3=quantile(percentage, 0.75), min=min(percentage), max=max(percentage))
summary_for_removed_libs$type = "Missing libraries"

summaries = rbind(summary_for_added_libs
                  , summary_for_removed_libs
)
summaries = summaries[order(summaries$parent_image, summaries$type),]
summaries[, c(1, 8, 6, 2, 3, 4, 5, 7)]


################# comparison of library count between the commmunity and official image

images_with_lib_count = sqldf("select image, parent_image, count(*) as lib_count from container_analysis_result group by image, parent_image")

for(parent_image in unique(images_with_lib_count$parent_image)){
  community_images = images_with_lib_count[images_with_lib_count$parent_image == parent_image & images_with_lib_count$parent_image != images_with_lib_count$image,]
  official_image = images_with_lib_count[images_with_lib_count$parent_image == parent_image & images_with_lib_count$parent_image == images_with_lib_count$image,]
  print(parent_image)
  
  community_images_having_more_lib_than_official = nrow(community_images[community_images$lib_count > official_image$lib_count,])/nrow(community_images)*100
  
  print(community_images_having_more_lib_than_official)
}

