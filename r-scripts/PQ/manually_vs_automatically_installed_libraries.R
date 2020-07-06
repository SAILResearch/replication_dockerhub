#This script counts the number of automatically and manually installed libraries and create a boxplot. It also prints the summary of that data.

if (!require("pacman")) install.packages("pacman")
pacman::p_load(conflicted, here, sqldf, ggplot2, plyr)

container_analysis_result = read.csv(here::here("data","container_analysis_result_for_five_images.csv"), header = TRUE, sep = ",")

manually_installed_libs = sqldf("select parent_image, image, count(distinct lib_with_version) as lib_count from container_analysis_result where is_auto_installed='False' group by parent_image, image")
manually_installed_libs$type = "Manually installed"
auto_installed_libs = sqldf("select parent_image, image, count(distinct lib_with_version) as lib_count from container_analysis_result where is_auto_installed='True' group by parent_image, image")
auto_installed_libs$type = "Automatically installed"

all_libs = rbind(auto_installed_libs, manually_installed_libs)

ggplot(all_libs, aes(x=parent_image, y=lib_count, fill=type)) + 
  geom_boxplot(outlier.shape=NA)+
  theme_test()+
  theme(legend.title = element_blank(), legend.position="top", )+
  xlab("")+
  ylab("# of installed libraries")


manual_lib_summary = ddply(manually_installed_libs, .(parent_image), plyr::summarise, avg=mean(lib_count), median=median(lib_count), 
                           q1=quantile(lib_count, 0.25), q3=quantile(lib_count, 0.75), min=min(lib_count), max=max(lib_count))
manual_lib_summary$type = "Manual"

auto_lib_summary = ddply(auto_installed_libs, .(parent_image), plyr::summarise, avg=mean(lib_count), median=median(lib_count),
                         q1=quantile(lib_count, 0.25), q3=quantile(lib_count, 0.75), min=min(lib_count), max=max(lib_count))
auto_lib_summary$type = "Auto"

lib_summaries = rbind(manual_lib_summary, auto_lib_summary)
lib_summaries = lib_summaries[order(lib_summaries$parent_image, lib_summaries$type),]
lib_summaries[, c(1, 8, 6, 2, 3, 4, 5, 7)]
