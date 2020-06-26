if (!require("pacman")) install.packages("pacman")
pacman::p_load(conflicted, here, sqldf, ggpubr)

container_analysis_result = read.csv("data/container_analysis_result_for_five_images.csv", header = TRUE, sep = ",")
container_analysis_result = container_analysis_result[which(container_analysis_result$os == "alpine"),]

container_analysis_result$parent_image = as.character(container_analysis_result$parent_image)
container_analysis_result$image = as.character(container_analysis_result$image)

container_analysis_with_lib_count = sqldf(
  "select image, parent_image, os, count(distinct library) as lib_count from container_analysis_result group by image, parent_image"
)


container_efficiency_result = read.csv(here::here("data","container_efficiency_result.csv"), header = TRUE, sep = ",")

image_metrics =  read.csv(here::here("data","metadata_for_five_images_samples.csv"), header = TRUE, sep = ",")

image_metrics= unique(image_metrics)

container_analysis_with_efficiency = sqldf(
  "select container_analysis_with_lib_count.*, container_efficiency_result.efficiency, container_efficiency_result.wastedBytes, container_efficiency_result.size
  from container_analysis_with_lib_count inner join container_efficiency_result
  on container_analysis_with_lib_count.image = container_efficiency_result.image
  and container_analysis_with_lib_count.os = container_efficiency_result.os"
)


container_analysis_with_efficiency = sqldf(
  "select container_analysis_with_efficiency.*, image_metrics.star_count, image_metrics.pull_count
  from container_analysis_with_efficiency inner join image_metrics
  on container_analysis_with_efficiency.image = image_metrics.image
  and container_analysis_with_efficiency.parent_image = image_metrics.parent_image "
)

container_analysis_with_efficiency$size = container_analysis_with_efficiency$size/1024/1024
container_analysis_with_efficiency$wasted_mb = container_analysis_with_efficiency$wastedBytes/1024/1024

plots = list()
parent_images = sort(unique(container_analysis_with_efficiency$parent_image))

efficiency_ans_size_comparisons = data.frame(
  image_type = character(),
  official_image_efficiency = numeric(),
  community_images_more_efficient = numeric(),
  community_images_bigger_size = numeric()
)

efficiency_vs_feature = data.frame(image_type = character(), p_value = numeric())

efficiency_vs_popularity_corr_test = data.frame(
  image_type = character(),
  star_corr_value = numeric(),
  pull_corr_value = numeric()
)

lib_count_vs_popularity = data.frame(
  image_type = character(),
  star_p_value = numeric(),
  star_cor_coff = numeric(),
  pull_p_value = numeric(),
  pull_cor_coff = numeric()
)

size_vs_others = data.frame(
  image_type = character(),
  size_vs_wasted_space = numeric(),
  size_vs_lib_count = numeric(),
  size_vs_lib_count_corr = numeric(),
  size_vs_wasted_space_corr = numeric()
)

community_image_efficiency_distributions = data.frame(
  image_type = character(),
  index = numeric(),
  image_percentage = numeric()
)
colors = c(rgb(100,129,248, maxColorValue = 255), rgb(207,72,65, maxColorValue = 255), 
           rgb(234,187,0, maxColorValue = 255), rgb(67,165,89, maxColorValue = 255), 
           rgb(240,116,0, maxColorValue = 255), rgb(108,192,208, maxColorValue = 255))

color_index = 1
for (parent_image in parent_images) {
  
  print(parent_image)
  
  community_images = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image
                                                        & container_analysis_with_efficiency$image != container_analysis_with_efficiency$parent_image, ]
  
  
  official_image = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image
                                                        & container_analysis_with_efficiency$image == container_analysis_with_efficiency$parent_image, ]
  
  community_images$rounded_efficiency = round(community_images$efficiency)
  official_image$rounded_efficiency = round(official_image$efficiency)
  
  current_community_image_efficiency_distribution = data.frame(
    image_type = character(),
    index = numeric(),
    image_percentage = numeric()
  )
  print(official_image)
  for (i in 0:100) {
    current_community_image_efficiency_distribution = rbind(
      current_community_image_efficiency_distribution,
      data.frame(
        image_type = parent_image,
        index = i,
        image_percentage =
          nrow(community_images[community_images$rounded_efficiency == i, ])/nrow(community_images)*100
      )
    )
  }
  
  community_image_efficiency_distributions = rbind(
    community_image_efficiency_distributions,
    current_community_image_efficiency_distribution
  )
  
  
  plots[[color_index]] <- local({
    i <- i
    official_image_y_index = as.numeric(current_community_image_efficiency_distribution$image_percentage[current_community_image_efficiency_distribution$index == official_image$rounded_efficiency])+1
    
    if (nrow(official_image) > 0) {
      p1 <- ggplot(data = current_community_image_efficiency_distribution
                   , aes(x = index, y = image_percentage)) +
        geom_bar(stat = "identity", fill = colors[color_index], width = 0.3) +
        theme_gray(base_size = 10)+
        ylab("% of images")+
        xlab("% of resource efficiency")+
        ylim(0,30)+ # chek x and y axis limits whether they miss any values and set accordingly
        xlim(40,101) +
              geom_point(data=official_image, aes(x=rounded_efficiency,
                         y=0),
                         colour="red", size=1, shape=8)
    } else {
      p1 <- ggplot(data = current_community_image_efficiency_distribution
                   , aes(x = index, y = image_percentage)) +
        geom_bar(stat = "identity", fill = colors[color_index], width = 0.6) +
        theme_gray(base_size = 10)+
        ylab("% of images")+
        xlab("% of resource efficiency")+
        ylim(0,30)+ # chek x and y axis limits whether they miss any values and set accordingly
        xlim(40,101)
      }
  })
  
  color_index = color_index +1

  official_image_efficiency = NA
  community_images_more_efficient = NA
  community_images_bigger_size = NA
  if (nrow(official_image) > 0) {
    official_image_efficiency = official_image$efficiency
    community_images_more_efficient = nrow(community_images[community_images$efficiency >= official_image$efficiency,])/nrow(community_images)*100
    community_images_bigger_size = nrow(community_images[community_images$size > official_image$size,])/nrow(community_images)*100
  }
   
  efficiency_ans_size_comparisons = rbind(
    efficiency_ans_size_comparisons,
    data.frame(
      image_type = parent_image,
      official_image_efficiency = official_image_efficiency,
      community_image_median_efficiency =  median(community_images$efficiency),
      community_images_more_efficient = community_images_more_efficient,
      community_images_bigger_size = community_images_bigger_size
    )
  )
  
  lib_count_test_result = wilcox.test(
    community_images$lib_count,
    community_images$efficiency,
    paired = TRUE,
    alternative = "two.sided"
  )
  
  efficiency_vs_feature = rbind(
    efficiency_vs_feature,
    data.frame(image_type = parent_image, p_value = lib_count_test_result$p.value)
  )
  
  star_count_test_result = cor.test(
    community_images$star_count,
    community_images$efficiency,
    method = c("spearman")
  )
  
  pull_count_test_result = cor.test(
    community_images$pull_count,
    community_images$efficiency,
    method = c("spearman")
  )
  
  efficiency_vs_popularity_corr_test = rbind(
    efficiency_vs_popularity_corr_test,
    data.frame(
      image_type = parent_image,
      pull_corr_value = pull_count_test_result$estimate,
      star_corr_value = star_count_test_result$estimate
    )
  )
  
  # Size vs lib count and wasted space:
  size_vs_wasted_space = wilcox.test(
    community_images$size,
    community_images$wasted_mb,
    paired = TRUE,
    alternative = "two.sided"
  )
  
  size_vs_wasted_space_corr = cor.test(
    community_images$size,
    community_images$wasted_mb,
    method = c("spearman")
  )
  
  size_vs_lib_count = wilcox.test(
    community_images$size,
    community_images$lib_count,
    paired = TRUE,
    alternative = "two.sided"
  )
  
  size_vs_lib_count_corr = cor.test(
    community_images$size,
    community_images$lib_count,
    method = c("spearman")
  )
  
  size_vs_others = rbind(
    size_vs_others,
    data.frame(
      image_type = parent_image,
      size_vs_lib_count = size_vs_lib_count$p.value,
      size_vs_wasted_space = size_vs_wasted_space$p.value,
      size_vs_lib_count_corr = size_vs_lib_count_corr$estimate,
      size_vs_wasted_space_corr = size_vs_wasted_space_corr$estimate
    )
  )
  
  star_vs_lib_count = wilcox.test(
    community_images$lib_count,
    community_images$star_count,
    paired = TRUE,
    alternative = "two.sided"
  )
  
  star_vs_lib_count_corr_test = cor.test(community_images$lib_count,
                                         community_images$star_count, method=c("spearman"))
  
  download_vs_lib_count = wilcox.test(
    community_images$lib_count,
    community_images$pull_count,
    paired = TRUE,
    alternative = "two.sided"
  )
  
  download_vs_lib_count_corr_test = cor.test(community_images$lib_count,
                                         community_images$pull_count, method=c("spearman"))
  
  
  lib_count_vs_popularity = rbind(
    lib_count_vs_popularity,
    data.frame(
      image_type = parent_image,
      star_p_value = star_vs_lib_count$p.value,
      star_cor_coff = star_vs_lib_count_corr_test$estimate,
      pull_p_value = download_vs_lib_count$p.value,
      pull_cor_coff = download_vs_lib_count_corr_test$estimate
      
    )
  )
  
}


ggarrange(plots[[1]], plots[[2]], plots[[3]], plots[[4]], plots[[5]], ncol = 3, nrow = 2, align = c("hv"),
          labels = parent_images,
          font.label = list(size = 10, color = "black", face = "bold", family = NULL),
          label.x = 0.2, label.y = 1, vjust = 2.5)


official_image_efficiencies = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == container_analysis_with_efficiency$image,]
community_image_efficiencies = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image != container_analysis_with_efficiency$image,]

ggplot(container_analysis_with_efficiency, aes(x=efficiency, y=lib_count, shape=parent_image, color=parent_image)) +
  geom_point()+
  xlab("% of efficiency")+
  ylab("# of libraries")+
  theme(legend.title=element_blank())+
  labs(color = "Image types", shape= "Image types")


container_analysis_with_efficiency = container_analysis_with_efficiency[order(container_analysis_with_efficiency$parent_image, -container_analysis_with_efficiency$efficiency),]


#write.csv(container_analysis_with_efficiency,
#          here::here("data","image_detail_with_efficiency.csv"))
##################################################################################################################

community_image_efficiencies$wasted_mb = community_image_efficiencies$wastedBytes/1024/1024
official_image_efficiencies$wasted_mb = official_image_efficiencies$wastedBytes/1024/1024


ggplot(community_image_efficiencies, aes(y=wasted_mb, x=reorder(parent_image, -wasted_mb, FUN = median), color=parent_image))+
  geom_boxplot()+
  theme(legend.position="none", panel.background = element_rect(fill = "white",colour = "black",
                                                                size = 0.5, linetype = "solid"))+
  xlab("")+
  ylab("wasted MB")+
  geom_point(data=official_image_efficiencies, aes(x=parent_image, 
                                      y=wasted_mb), 
             colour="red", size=1, shape=8)+
  scale_y_continuous(trans='log1p')
 
print("size summary")
for(parent_image in parent_images){
  print(parent_image)
  
  current_images = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]
  current_official_image = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image & 
                                                        container_analysis_with_efficiency$parent_image == container_analysis_with_efficiency$image,]
  
  #print(summary(current_images$size))
  print("IQR:")
  print(IQR(current_images$size))
  print("IQR % of official image size:")
  print(IQR(current_images$size)/current_official_image$size*100)
}

print("wasted mb summary")
for(parent_image in parent_images){
  print(parent_image)

  print(summary(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$wasted_mb))
  print(IQR(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$wasted_mb))
}

ggplot(container_analysis_with_efficiency, aes(y=size, x=reorder(parent_image, -size, FUN = median)))+
  geom_boxplot()+#outlier.shape = NA)+
  theme(legend.position="none")+
  theme(axis.text=element_text(size=24), text = element_text(size=24)) + 
  xlab("")+
  ylab("size in MB")+
  geom_point(data=official_image_efficiencies, aes(x=parent_image, 
                                                   y=size), 
             colour="red", size=2, shape=8)#+
  #scale_y_continuous(trans='log1p')


print("efficiency differences")
for(parent_image in parent_images){
  print(parent_image)
  
  print(summary(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$efficiency))
  print(IQR(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$efficiency))
  print((max(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$efficiency) - min(container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]$efficiency)))
}


#--------------------------------------------------------
#Select top 10 efficiecnt images for each software system
#--------------------------------------------------------
flag = 0
top_efficient_images = container_analysis_with_efficiency
for(parent_image in unique(container_analysis_with_efficiency$parent_image)){
 community_images = container_analysis_with_efficiency[container_analysis_with_efficiency$parent_image == parent_image,]
 
 if(flag == 0){
   top_efficient_images = community_images[order(-community_images$efficiency),][1:10,]
   flag = flag +1 
 }else{
   top_efficient_images = rbind(top_efficient_images, community_images[order(-community_images$efficiency),][1:10,])
 }
}

write.csv(top_efficient_images, file=here::here("data", "top_efficient_images.csv"))

          