library(maps)
library(ggplot2)
getwd()
setwd("C:/Users/sunnyzou/Desktop/wellbeing")
data = read.csv("./wellbeing2.csv")
states <- map_data("state")
colnames(data)[2]<-"region"
Total <- merge(states, data, by="region")
Total
colnames(Total)[8]<- "Score"
p <- ggplot() + geom_polygon(data=Total, 
                             aes(x=long, y=lat, group = group, fill=Score),
                             color="#ffffff",
                             size=0.15) +
  scale_fill_continuous(low='thistle2', high='darkred', guide='colorbar') +
  theme(plot.title=element_text(hjust=.5))+
  ggtitle("Total Wellbeing Score by State") 

p
