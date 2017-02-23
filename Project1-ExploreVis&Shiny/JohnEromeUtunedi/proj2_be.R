

# Read Refugee data from csv file
data = read.csv("Project2/data/refugee_status.csv", stringsAsFactors = FALSE)
data = tbl_df(data[data$Continent.Country.of.Nationality != "Total",])

#Format continental data
Continent_data = data[1:7,]
Continent_data_row = nrow(Continent_data)
Continent_data_col = ncol(Continent_data)
Continent_data[,2:Continent_data_col] = tbl_df(lapply(Continent_data[,2:Continent_data_col], gsub, patt = ",", replacement = ""))
Continent_data[,2:Continent_data_col] = tbl_df(lapply(Continent_data[,2:Continent_data_col], as.numeric))
colnames(Continent_data)[1] = "Location"
Continent_data = Continent_data[!Continent_data$Location %in% c("Oceania"),]
Continent_data[is.na(Continent_data)] = 0
Continent_data = melt(Continent_data, id = "Location")
Continent_data[,2] = as.character(Continent_data[,2])
Continent_data[[2]] = substr(Continent_data[[2]],2,5)
Continent_data[,2] = as.numeric(Continent_data[,2])
names(Continent_data) = c("Continent","Year","Refugee.Status")


#Format Country data
Country_data = data[8:nrow(data),]
Country_data_row = nrow(Country_data)
Country_data_col = ncol(Country_data)
Country_data[,2:Country_data_col] = tbl_df(lapply(Country_data[,2:Country_data_col], gsub, patt = ",", replacement = ""))
Country_data[,2:Country_data_col] = tbl_df(lapply(Country_data[,2:Country_data_col], as.numeric))
Country_data[is.na(Country_data)] = 0
colnames(Country_data)[1] = "Location"
Country_data = melt(Country_data, id = "Location")
Country_data[,2] = as.character(Country_data[,2])
Country_data[[2]] = substr(Country_data[[2]],2,5)
Country_data[,2] = as.numeric(Country_data[,2])
names(Country_data) = c("Country","Year","Refugee.Status")

#Identify map by country and continent
map.world = map_data(map = "world")
map.world = subset(map.world, region!="Antarctica")
Country_data_match = merge(Country_data, map.world, by.x = "Country", by.y = "region")
Country_data_match = arrange(Country_data_match, group, order)


# The purpose of this function is to plot
# a bar chart indicating the top/least 2-6 Continents
# from where refugees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
ContinentFilterBar.Plotly = function(data1 = Continent_data, fil = "2006", height = 2, arrange = 1) {
  if(arrange == 1) {
    temp = arrange(filter(data1, Year == fil),desc(Refugee.Status))[1:height,]
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$Refugee.Status)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Refugee.Status, type = "bar", color = ~Continent,
                            colors = 'Set2') %>% layout(title = paste("Largest Refugee Continents in", fil), xaxis =list(title = ""), yaxis = list(title = "Total Refugees"))
  }
  else {
    temp = arrange(filter(data1, Year == fil),Refugee.Status)[1:height,] 
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(temp$Refugee.Status)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Refugee.Status, type = "bar", color = ~Continent,
                            colors = 'Set2') %>% layout(title = paste("Smallest Refugee Continents in",fil), xaxis =list(title = ""), yaxis = list(title = "Total Refugees"))
  }
  return(val)
}

# The purpose of this function is to view the Refugees from each continent
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-6
# continents from which refugees come from
ContinentFilterTotal.Plotly = function(data = Continent_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Refugee.Status)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Continent)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Refugee.Status, type = 'bar', color = ~Continent, 
            colors = 'Set2')
  } else {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Refugee.Status, color = ~Continent, colors = 'Set2',
            size = ~Refugee.Status*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Continents containing people with Refugee Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Refugee Total"), barmode = 'stack')
}

# The purpose of this function is to display the continents
# with the most Refugees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-6 continets 
ContinentFilterSum.Plotly = function(data = Continent_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Refugee.Status)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, type = 'bar', color = I('blue'))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, color = ~Continent, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Top", amt, "Continents containing people with Refugee","<br />","Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Refugee Total"))
}

# The purpose of this function is to plot
# a bar chart indicating the top/least 2-10 Countries
# from where refugees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
CountryFilterBar.Plotly = function(data = Country_data, Year_val = 2006, height = 10, arrange = 1) {
  if(arrange == 1) {
  temp = arrange(filter(data, Year == Year_val, Refugee.Status!=0), desc(Refugee.Status))[1:height,]
  temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$Refugee.Status)], ordered = TRUE)
  plot_ly(data = temp, x = ~Refugee.Status, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',marker = list(reversescale = TRUE),
          text = ~paste('Country:',Refugee.Status)) %>%  
    layout(title = paste("Largest Refugee Countries in", Year_val), xaxis =list(title = "Total Refugees"), yaxis = list(title = "", tickangle = 70)) }
  else {
    temp = arrange(filter(data, Year == Year_val, Refugee.Status!=0), Refugee.Status)[1:height,]
    temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(temp$Refugee.Status)], ordered = TRUE)
    plot_ly(data = temp, x = ~Refugee.Status, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',
             marker = list(reversescale = TRUE),
            text = ~paste('Country:',Country), hoverinfo = 'all') %>% 
      layout(title = paste("Smallest Refugee Countries in", Year_val), xaxis =list(title = "Total Refugees"), yaxis = list(title = "", tickangle = 70))
  }
}

# The purpose of this function is to view the Refugees from each country
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-10
# countries from which refugees come from
CountryFilterTotal.Plotly = function(data = Country_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Refugee.Status)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Country)
  temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Refugee.Status, type = 'bar', color = ~Country, 
          colors = 'Accent')
  } else {
  temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Refugee.Status, color = ~Country, 
                      colors = "Accent",
          size = ~Refugee.Status, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Countries containing people with Refugee Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Refugee Total"), barmode = 'stack')
}

# The purpose of this function is to display the countries
# with the most Refugees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-10 countries 
CountryFilterSum.Plotly = function(data = Country_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Refugee.Status)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, type = 'bar', color = I("blue"))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, color = ~Country, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Top", amt, "Countries containing people with Refugee","<br />","Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Refugee Total"))
}

# The purpose of this function is to create a trend plot to allow the user
# to compare individual countries against the total refugees per year. 
# Used with shiny, the user can select multiple countries and compare them
# against the total refugees for each year
CountryFilterUsrInteract.Plotly = function(data = Country_data, var = "Nigeria") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Refugee.Status))
  plot_ly() %>% add_trace(data = filter(data, Country %in% c(var)), x = ~Year, y = ~Refugee.Status, color = ~Country, type = 'scatter', 
          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>% 
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"),
              line = list(width = 5, dash = 'dash', shape = 'spline'),showlegend = TRUE) %>%
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Refugee Total"))
}

# The purpose of this function is to create a trend plot to allow the user
# to compare each continent against the total refugees per year.
# Used with shiny, the user can select multiple continents and compare them
# against the total refugees for each year
ContinentFilterUsrInteract.Plotly = function(data = Continent_data, var = "Africa") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Refugee.Status))
  plot_ly() %>% add_trace(data = filter(data, Continent %in% c(var)), x = ~Year, y = ~Refugee.Status, color = ~Continent, type = 'scatter', 
                          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>%
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"),
              line = list(width = 5, dash = 'dash', shape = 'spline')) %>% 
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Refugee Total"))
}

# The purpose of this function is to create a bar plot to
# display the total refugees per year
Total.Plotly = function(data = Continent_data) {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Refugee.Status))
  plot_ly() %>% add_trace(data =temp, x = ~Year, y = ~sum, name = "Total Refugees",type = 'bar', 
                          color = ~sum,text = ~paste("Year:",Year,"<br />Total:",sum),hoverinfo = 'text',
                          colors = brewer.pal(9,'Reds'), marker = list(colorbar = list(title = "Refugee Total"))) %>%
    layout(xaxis = list(title = ""), yaxis = list(title = "Refugee Total"), paper_bgcolor = 'rgb(160,160,160)',
           plot_bgcolor = 'rgb(160,160,160)')
}


## 
