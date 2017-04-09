library(ggplot2)
library(dplyr)
library(tidyr)
library(reshape2)
library(wordcloud)
library(SnowballC)
library(tm)
library(RColorBrewer)

#------------Read Datasets -----------------------------------------------------------------------#
vehicle <- read.csv("./Carmax/vehicle_listing1.csv", header=TRUE, stringsAsFactors = FALSE)

#------------Data Cleaning -------------------------------------------------#
#convert customer stat to numeric
vehicle$price <- gsub("[$]", " ", vehicle$price)
vehicle$price <- as.integer(gsub("[,]", "", vehicle$price))
vehicle$year <- as.character(vehicle$year)
vehicle$mileage <- (gsub("[,]", "", vehicle$mileage))
vehicle$mileage <- as.integer((gsub("[K]", "000", vehicle$mileage)))
average = aggregate(vehicle$price, list(vehicle$year), mean)

#1. Find car brands most available in carmax across Viginia
ggplot(vehicle, aes(factor(make, levels = names(sort(table(make)))))) +
  geom_bar(aes(fill=year)) + 
  coord_flip() +
  theme_bw() +
  xlab("Brand of sedan") +
  ylab("Number of cars available") +
  theme(axis.ticks=element_blank(), panel.grid=element_blank())+
  ggtitle("Brand and year of used cars most available in Carmax across Virginia")

ggsave("popular_brand.png", last_plot(), scale = 1)

#2. create wordcloud of features
feat_df <- strsplit(vehicle$feature_list, ",")
feat_df <- unlist((feat_df))
#feat_data  <-  as.data.frame(matrix(feat_df), nrow=length(feat_df))
feat_data  <-  as.data.frame(feat_df)
names(feat_data) = "feature"
feat_data[feat_data$feature == " Cruise Control",] <- "Cruise Control"
feat_data[feat_data$feature == "Auto Cruise Control",] <- "Cruise Control"
feat_data[feat_data$feature == " Auto Cruise Control",] <- "Cruise Control"
feat_data[feat_data$feature == "Auto Cruise Control ",] <- "Cruise Control"


feat_table <- feat_data %>%
  group_by(feature) %>%
  summarize(count = n()) %>%
  arrange(desc(count))

wordcloud(feat_table$feature,feat_table$count, scale=c(2,1), min.freq = 1,
          random.order=FALSE, random.color=FALSE, colors=brewer.pal(8, "Dark2"))

png("wordcloud.png", width=12, height=8, units="in", res=300)
wordcloud(feat_table$feature,feat_table$count, scale=c(2,1), min.freq = 1,
          random.order=FALSE, random.color=FALSE, colors=brewer.pal(8, "Dark2"))
dev.off()

#3. Histogram of price range
ggplot(vehicle, aes(price)) +
  geom_histogram() +
  xlab("Price" ) 
ggsave("price_range.png", last_plot(),  width=12, height=8, units="in", res=300)

#4. Histogram of mileage
ggplot(vehicle, aes(mileage)) +
  geom_histogram() +
  xlab("Mileage" ) 

ggsave("mileage_range.png", last_plot(),  width=12, height=8, units="in", res=300)

#5. Detemine the year of car using Scatter plot of price and mileage
vehicle$price <- jitter(vehicle$price, factor=0.5)
#vehicle$mileage <- jitter(vehicle$mileage, factor=0.5)
ggplot(vehicle, aes(y=mileage, x=price, color=year)) +
  geom_point(size=2) +
  #    geom_abline(average, aes(year, price)) +
  geom_smooth(method = "lm", se=FALSE) +
  #  facet_wrap(~Sector, scale="free_y") + 
  ylab("Mileage" ) +
  xlab("Price" ) +
  scale_color_brewer(palette = 'Paired') +
  #scale_y_discrete(limits=c(2006:2017)) +
  #  theme(legend.position="right") +  theme(panel.grid=element_blank(), legend.key=element_blank())+
  ggtitle("Price  Vs  Mileage (Year correlation)")

ggsave("scatterplot_price.png", last_plot(),  width=12, height=8, units="in", res=300)

#6. Find max/ min sale price of car by year (the difference in max price is introduced due to luxury sedans)
ggplot(vehicle, aes(x=year, y=price)) +
  geom_boxplot(aes(col=year))+
  scale_x_discrete(limits=c(2006:2017)) +
  theme(panel.grid=element_blank(), legend.key=element_blank(), axis.text.x=element_text(angle=90))
  #    geom_abline(average, aes(year, price)) +
ggsave("max_min_price.png", last_plot(),  width=12, height=8, units="in", res=300)

#7.
vehicle$price_range <-cut(vehicle$price, breaks = seq(0,50000,5000), 
                    labels=c("0-5k", "5k-10k", "10k-15k", "15k-20k", "20k-25k", 
                          "25k-30k", "30k-35k", "35k-40k", "40k-45k", ">45k"))
brand_car <- vehicle %>%
#  filter(year < '2017') %>%
  group_by(location, make) %>%
  summarise(avg_price=mean(price), count = n())
#  filter(count > 5) %>%
#arrange(desc(count), location)


ggplot(brand_car, aes(x=location, y=make))+
  geom_tile(aes(fill=avg_price), alpha=0.8, size=2, color="white")+
  scale_fill_gradient2(low="darkblue", high="darkgreen", guide="colorbar") +
  xlab("Store Location") +
  ylab("Sedan Brand") +
  ggtitle("Heatmap to find average price for a sedan brand at a location")

ggsave("heatmap.png", last_plot(),  width=12, height=8, units="in", res=300)
  