library(ggplot2)
library(sqldf)
library(ggpubr)

container_efficiency_result = read.csv(file = "data/container_efficiency_result.csv", header =
                                         TRUE, sep = ",")
container_efficiency_result = container_efficiency_result[which(container_efficiency_result$os=="debian"),]

image_detail_with_vulnerabilities = read.csv(file = "data/image_detail_with_vulnerabilities.csv", header =
                                               TRUE, sep = ",")
image_detail_with_vulnerabilities$X=NULL
image_detail_with_vulnerabilities=unique(image_detail_with_vulnerabilities)

images_efficiency_and_vuls = sqldf("select image_detail_with_vulnerabilities.*, container_efficiency_result.efficiency
                          from container_efficiency_result inner join image_detail_with_vulnerabilities 
                                    on container_efficiency_result.image = image_detail_with_vulnerabilities.image")

images_efficiency_and_vuls$image = as.character(images_efficiency_and_vuls$image) 
images_efficiency_and_vuls$parent_image = as.character(images_efficiency_and_vuls$parent_image)


labels = c("more efficient; less vulnerable images","more efficient; more vulnerable images", "less efficient; less vulnerable images", "less efficient; more vulnerable images", "official image")
colors = c(rgb(8,144,0, maxColorValue = 255), "blue", rgb(196,145,2, maxColorValue = 255), "red", "black")

plots = list()
#parent_images = sort(unique(images_efficiency_and_vuls$parent_image))
parent_images<-c("cassandra","java","mysql","nginx")
#images_efficiency_and_vuls$efficiency = round(images_efficiency_and_vuls$efficiency)

color_index = 1
for (parent_image in parent_images) {
  
  print(parent_image)
  
  community_images = images_efficiency_and_vuls[images_efficiency_and_vuls$parent_image == parent_image
                                                       & images_efficiency_and_vuls$image != images_efficiency_and_vuls$parent_image, ]
  print('correlation between vulnerabilities and resource efficiency:')
  print(cor.test(community_images$efficiency, community_images$total_vuls, method="spearman")$estimate)
  
  
  official_image = images_efficiency_and_vuls[images_efficiency_and_vuls$parent_image == parent_image
                                                     & images_efficiency_and_vuls$image == images_efficiency_and_vuls$parent_image, ]
  
  official_image_efficiency = as.numeric(official_image$efficiency)
  official_image_vuls = as.numeric(official_image$total_vuls)
  
  
  better_efficiency_and_security = community_images[community_images$efficiency > official_image_efficiency & community_images$total_vuls < official_image_vuls,]
  
  better_efficiency = community_images[community_images$efficiency > official_image_efficiency & community_images$total_vuls >= official_image_vuls,]
  
  better_security = community_images[community_images$efficiency <= official_image_efficiency & community_images$total_vuls < official_image_vuls,]
  
  bad_images = community_images[community_images$efficiency < official_image_efficiency & community_images$total_vuls > official_image_vuls,]

  print('nbre community images:')
  print(nrow(community_images))
  print('% images better in efficiency and security:')
  print(nrow(better_efficiency_and_security)/nrow(community_images))
  #print(nrow(better_efficiency))
  #print(nrow(better_security))
  #print(nrow(bad_images))
  
  plots[[color_index]] <- local({
    p1 <- ggplot() +
      xlab("% of efficiency")+
      geom_point(data=better_efficiency, aes(x=efficiency, y=total_vuls), size=1, color=colors[2], shape=2)+
      geom_point(data=better_security, aes(x=efficiency, y=total_vuls), size=1, color=colors[3], shape=3)+
      geom_point(data=bad_images, aes(x=efficiency, y=total_vuls), size=1, color=colors[4], shape=4)+
      geom_point(data=better_efficiency_and_security, aes(x=efficiency, y=total_vuls), size=1, color=colors[1], shape=1)+
      ylab("# of vulnerabilities")+
      geom_point(data=official_image, aes(x=efficiency,
                                          y=total_vuls),
                 colour=colors[5], shape=8, size=1)+
      #ylim(c(0,300))+
      #xlim(c(40, 100))+
      #scale_y_continuous(trans='log1p')+
      theme_test()
  })
  
  color_index = color_index +1
  print("--------------------------")
}



# The following code is to only generate appropriate legend #############
community_images[1:20,"type"] = labels[1]
community_images[21:40,"type"] = labels[2]
community_images[41:60,"type"] = labels[3]
community_images[61:80,"type"] = labels[4]
community_images[81:102,"type"] = labels[5]


community_images = community_images[order(-community_images$efficiency),]

community_images$type <- factor(community_images$type, levels = labels)

plots[[5]] <- get_legend(
  ggplot(data = community_images, 
         aes(x = efficiency, y = total_vuls,  color=type, shape=type)
         ) + 
  geom_point()+
    scale_color_manual(values = colors)+
    scale_shape_manual(values = c(1,2,3,4,8))+
    theme(legend.title = element_blank()))

#########################################################################

ggarrange(plots[[1]], plots[[2]], plots[[3]], plots[[4]], plots[[5]]#, plots[[6]]
          , ncol = 2, nrow = 3, align = c("hv"),
          labels = parent_images,
          font.label = list(family = NULL, size=11),
          label.x = 0.20, label.y = 1, vjust = 2.5)


