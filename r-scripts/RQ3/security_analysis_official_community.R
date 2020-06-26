library(ggplot2)

library(dplyr)
library(plotly)
library(xtable)

library(reshape)
library(reshape2)
library(flexclust)
library(proxy)

library(boot)
library(ggpubr)

image_detail_with_vulnerabilities = read.csv(file = "data/image_detail_with_vulnerabilities.csv", header =
                                       TRUE, sep = ",")


image_detail_with_vulnerabilities_community = image_detail_with_vulnerabilities[as.character(image_detail_with_vulnerabilities$parent_image)
                                                                                != as.character(image_detail_with_vulnerabilities$image),]

image_detail_with_vulnerabilities_official = image_detail_with_vulnerabilities[as.character(image_detail_with_vulnerabilities$parent_image)
                                                                                == as.character(image_detail_with_vulnerabilities$image),]


#aes(y=wasted_mb, x=reorder(parent_image, -wasted_mb, FUN = median), color=parent_image)
# image_detail_with_vulnerabilities_community$total_vuls_boxplot = image_detail_with_vulnerabilities_community$total_vuls
# image_detail_with_vulnerabilities_community[image_detail_with_vulnerabilities_community$total_vuls_boxplot == 0,]$total_vuls_boxplot = 1
ggplot(image_detail_with_vulnerabilities_community, aes(y=total_vuls, x=reorder(parent_image, -total_vuls, FUN=median)))+#, color=parent_image
  geom_boxplot()+
  #ylim(0,25)+
  theme(legend.position="none", axis.text=element_text(size=24), text = element_text(size=24))+
  xlab("")+
  ylab("# of all security vulnerabilities")+
  geom_point(data=image_detail_with_vulnerabilities_official, aes(x=parent_image, y=total_vuls), colour="red", size=4, shape=8)#+
 #theme_test()
#+
#  scale_y_log10()


for(parent_image in unique(image_detail_with_vulnerabilities_community$parent_image)){
  print(parent_image)
  print(summary(image_detail_with_vulnerabilities_community[image_detail_with_vulnerabilities_community$parent_image == parent_image,]$total_vuls))
  print(IQR(image_detail_with_vulnerabilities_community[image_detail_with_vulnerabilities_community$parent_image == parent_image,]$total_vuls))
}


#aes(y=wasted_mb, x=reorder(parent_image, -wasted_mb, FUN = median), color=parent_image)
ggplot(image_detail_with_vulnerabilities_community, aes(y=total_high_vuls, x=reorder(parent_image, -total_high_vuls, FUN=median)))+#, color=parent_image
  geom_boxplot()+
  #ylim(0,250)+
  theme(legend.position="none")+
  xlab("")+
  ylab("# of high security vulnerabilities")+
  geom_point(data=image_detail_with_vulnerabilities_official, aes(x=parent_image, y=total_high_vuls), colour="red", size=2, shape=8)+
  #scale_y_continuous(trans="log1p")+
  theme_test()



for(parent_image in unique(image_detail_with_vulnerabilities_community$parent_image)){
  print(parent_image)
  print(summary(image_detail_with_vulnerabilities_community[image_detail_with_vulnerabilities_community$parent_image == parent_image,]$total_high_vuls))
  print(IQR(image_detail_with_vulnerabilities_community[image_detail_with_vulnerabilities_community$parent_image == parent_image,]$total_high_vuls))
  
}


test_results = data.frame(image_type = character(), lib_vs_vul = numeric(), lib_vs_high_vuls=numeric(), image_couont_no_vuls=numeric())

top_secured_images = data.frame(parent_image=character(), image=character(), total_vuls=numeric())


most_secured_images = community_images

for (parent_image in unique(image_detail_with_vulnerabilities$parent_image)) {
  
  print(parent_image)
  parent_image = as.character(parent_image)
  
  community_images = image_detail_with_vulnerabilities[as.character(image_detail_with_vulnerabilities$parent_image) == as.character(parent_image)
                                   & 
                                     as.character(image_detail_with_vulnerabilities$image) != as.character(image_detail_with_vulnerabilities$parent_image), ]
  
  official_image = image_detail_with_vulnerabilities[as.character(image_detail_with_vulnerabilities$parent_image) == as.character(parent_image)
                                 &
                                   as.character(image_detail_with_vulnerabilities$image) == as.character(image_detail_with_vulnerabilities$parent_image), ]
  
  lib_count_vs_vuls_test_result = cor.test(
    community_images$lib_count,
    community_images$total_vuls,
    method = "spearman"
  )

  lib_count_vs_high_vuls_test_result = cor.test(
    community_images$lib_count,
    community_images$total_high_vuls,
    method = "spearman"
  )

  test_results = rbind(
    test_results,
    data.frame(image_type = parent_image, lib_vs_vul = lib_count_vs_vuls_test_result$estimate
               , lib_vs_high_vuls=lib_count_vs_high_vuls_test_result$estimate,
               image_count_no_vuls=nrow(community_images[community_images$total_vuls == 0,])/nrow(community_images)*100,
               better_than_official=nrow(community_images[community_images$total_vuls < official_image$total_vuls,])/nrow(community_images)*100))
  
  community_images = community_images[order(community_images$total_vuls),]
  community_images<-unique(community_images)
  top_10_secured_images = community_images[1:10,c('parent_image','image','total_vuls')]
  top_secured_images = rbind(top_secured_images, top_10_secured_images)
  
  print("# of images less high security vul:")
  print(nrow(community_images[community_images$total_high_vuls < official_image$total_high_vuls,]))
  
  print("# of images do not high security vul:")
  print(nrow(community_images[community_images$total_high_vuls == 0,]))
}

write.csv(top_secured_images, "data/top_secured_images.csv")
write.csv(test_results, "~/data/output/lib_count_vs_vuls_test_results.csv")

