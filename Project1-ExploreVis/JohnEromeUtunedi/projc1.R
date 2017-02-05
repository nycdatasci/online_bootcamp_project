library(dplyr)
library(ggplot2)
library(maps)
library(ggthemes)
counties = map_data('county')
states = map_data('state')

## Function to determine total killed in each year
total_sum = function(dataset, year) {
  if(year == 2015) {
  ans = as.numeric(summarise(filter(dataset, year == 2015), total = sum(n())) )
  } else if(year == 2016) {
  ans = as.numeric(summarise(filter(dataset, year == 2016), total = sum(n())) ) 
  }else {
    return("Invalid year - Pick either 2015 or 2016")
  }
  return(ans)
}

## function to group and summarise dataset based on
## race, weapon on victim and weapon used to kill victim
groupby_sum = function(dataset, group1, t_2015, t_2016) {
  if(group1 == 'raceethnicity') {
    temp = group_by(dataset, raceethnicity,year)
  }else if (group1 == 'armed') {
    temp = group_by(dataset, armed, year)
  } else if(group1 == 'classification') {
    temp = group_by(dataset, classification, year)
  } else {
    return("Invalid Group - Pick 'raceethnicity', 'armed', 'classification'")
  }
  temp1 = summarise(temp, total = sum(n()))
  ans = mutate(temp1, percentage = ifelse(year == 2015, (total/t_2015)*100, (total/t_2016)*100 ))
  return(ans)
}

## Uploading data from .CSV files
police_vio_15 = read.csv('2015.csv')
police_vio_16 = read.csv('2016.csv')

## Merging data froom 2015 and 2015
police_vio_total = rbind(police_vio_15, police_vio_16)

## Obtaining states full name and merging with police violence data
state_abb = data.frame(full = state.name,state = state.abb)
police_vio_total = inner_join(police_vio_total,state_abb, by = 'state')

## change factor type in data into numeric and character for age and state respectively
police_vio_total = mutate(police_vio_total, age.numeric = as.numeric( as.character(police_vio_total$age) ))
police_vio_total = mutate(police_vio_total, region = as.character(police_vio_total$full))

## obtain total killed in 20156 and 2016
total_2015 = total_sum(police_vio_total, 2015)
total_2016 = total_sum(police_vio_total, 2016)

## group by race, weapon on victim when killed, and type of weapon used to kill victim
## and obtain total killed based on those groupings
## including percentages based on the groupings indicated above
race_sum = groupby_sum(police_vio_total, 'raceethnicity', total_2015, total_2016)
armed_sum = groupby_sum(police_vio_total,'armed', total_2015, total_2016)
classification_sum = groupby_sum(police_vio_total, 'classification', total_2015, total_2016)

## group police violence data based on state
by_state = summarise(group_by(police_vio_total, region, state, year), total = 
                       sum(n()))
by_state$region = tolower(by_state$region)
by_state_merge = inner_join(states, by_state, by = 'region')


## plots for presentation
## total killed in each state in 2015 and 2016
gg5 = ggplot(by_state_merge) + geom_polygon(aes(x = long, y = lat, fill = total, group = group), color = "black") + 
  scale_fill_gradient(low = 'yellow', high = 'red', name = "Total Killed")
gg5 = gg5 + ggtitle("Police Violence in 2015 & 2016 - By State") + xlab('Longitude') + ylab("Latitude") + 
  theme(legend.position = 'bottom') + theme_dark()
temp = summarise(group_by(by_state_merge,region,state), long = mean(long), lat = mean(lat))
gg5 + geom_text(data = temp, aes(x = long, y = lat, label = state), size = 5) + facet_grid(. ~ year) 

## total killed grouped by race
gg1 = ggplot(race_sum, aes(x = reorder(raceethnicity,total,median), y = total)) + geom_bar(aes(fill = as.factor(year)),
                                                                                           stat = 'identity', position =
                                                                                             'dodge')
gg1 = gg1 + ggtitle('Police Violence in 2015 & 2016 - By Race') + xlab('Ethnicity') + ylab('Total killed') + 
  theme(legend.position = "bottom") + scale_fill_discrete(name = "Year")

## total killed grouped by ethnicity in 2015 and 2016 
ggplot(data = summarise(group_by(police_vio_total, raceethnicity, year), Year_total = sum(n())) ) + 
  geom_bar(aes(x = reorder(raceethnicity, Year_total), y = Year_total, fill = raceethnicity ), stat = 'identity') + 
  facet_grid(year ~ .) + ggtitle('Police Violence - Grouped by year and Race') +
  xlab('Ethnicity') + ylab('Total Killed') + theme(legend.position = 'bottom') + 
  scale_fill_discrete(name = 'Ethnicity') + theme_dark()

## total killed in 2015 and 2016 grouped by White, Black and Hispanic/Latino ethnicity, and gender
ggplot(data = summarise(group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), 
                                        gender != "Non-conforming"), raceethnicity, year, gender), total = sum(n()) ) )+ 
  geom_bar(aes(x = reorder(raceethnicity, total, mean), y = total, fill = raceethnicity), stat = 'identity', position = 'dodge') + 
  facet_grid(gender ~ year) + theme_dark() +
  theme(legend.position = 'bottom') + ggtitle('Police Violence in 2015 & 2016 - Grouped by gender') + 
  xlab('Ethnicity') + ylab("Total Killed") + scale_fill_discrete(name = "Ethnicity")

## total killed in 2015 and 2016 grouped by White, Black, and Hispanic/Latino ethnicity, and 
## weapon on victim when killed
data1 = group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), gender == 'Male' ), 
                 raceethnicity, armed, year)
data1 = summarise(data1, total = sum(n()))
gg2 = ggplot(data = data1) +
  geom_bar(aes(x = reorder(armed, total, mean), y = total, fill = raceethnicity), stat = 'identity', position = 'dodge') + 
  facet_grid(year ~ .)
gg2 = gg2 + ggtitle("Police Violence in 2015 & 2016 - By Weapon") + xlab("Weapon of use") + ylab("Total Killed") + 
  theme(legend.position = "bottom") + scale_fill_discrete(name = "Year")

## total killed in 2015 and 2016 grouped by White, Black, and Hispanic/Latino ethnicity, and 
## cause of death of victim
data2 = group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), gender== "Male"), 
                 raceethnicity, classification, year)
data2 = summarise(data2, total = sum(n()))
gg3 = ggplot(data = data2) +
  geom_bar(aes(x = reorder(classification, total, mean), y = total, fill = raceethnicity), position = 'dodge', stat = 'identity') + 
  facet_grid(. ~ year)
gg3 = gg3 + ggtitle("Police Violence in 2015 & 2016 - by Classification") + xlab("Classification") + ylab("Total Killed") + 
  theme(legend.position = "bottom") + scale_fill_discrete(name = "Year")

## Age range of victims based on White, Black, and Hispanic/Latino ethnicities
data3 = group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), gender== "Male"), 
                 raceethnicity)
gg4 = ggplot(data = data3) +
  geom_boxplot(aes(x = reorder(raceethnicity, age.numeric, median), y = age.numeric, fill = raceethnicity), na.rm = TRUE, varwidth = TRUE, notch = FALSE) + 
  facet_grid(. ~ year) 
gg4 = gg4 + ggtitle("Police Violence in 2015 - Grouped by Race") + xlab('Ethnicity') + ylab("Age") + 
  theme(legend.position = 'bottom') + scale_fill_discrete(name = 'Ethnicity')

## Extra plot not required 
## Total killed in 2015 and 2016 based on weapon on victim and cause of victim death 
ggplot(data = summarise(group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), 
                                        gender == "Male"), raceethnicity, armed, classification, year), total = sum(n()) ) ) + 
  geom_bar(aes(x = reorder(raceethnicity, total, mean), y = total, fill = raceethnicity), stat = 'identity') + 
  facet_grid(armed ~ classification) + ggtitle('Police Violence in 2015 & 2016') + xlab('Ethnicity') + 
  ylab('Total Killed') + theme(legend.position = "bottom") + scale_fill_discrete(name = "Ethnicity") + theme_dark()

## Total killed in 2015 and 2016 based on weapon on victim and cause of victim death 
ggplot(data = summarise(group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"), 
                                        gender == "Male"), raceethnicity, armed, classification, year), total = sum(n()) ) ) +
  geom_raster(aes(x = armed, y = classification, fill = total), interpolate = TRUE) + 
  scale_fill_gradient(name = "Total Killed", low = 'yellow', high = 'red') + facet_grid(. ~ year) + theme_dark() +
  ggtitle('Total Killed in 2015 & 2016 Grouped by Weapon Use and Method of Death') +
  xlab("Armed Weapon") + ylab('Method of death')

## Total killed in 2015 and 2016 based on weapon on victim and cause of victim death
## grouped by race
ggplot(data = summarise(group_by(filter(police_vio_total, raceethnicity %in% c("White", "Black", "Hispanic/Latino"),
                                        gender == "Male"), raceethnicity, armed, classification, year), total = sum(n()) ) ) +
  geom_raster(aes(x = armed, y = classification, fill = total), interpolate = TRUE) + 
  scale_fill_gradient(name = "Total Killed", low = 'yellow', high = 'red') + facet_grid(raceethnicity ~ year) + theme_dark() +
  ggtitle('Total Killed in 2015 & 2016 Grouped by Weapon Use and Method of Death') +
  xlab("Armed Weapon") + ylab('Method of death')
