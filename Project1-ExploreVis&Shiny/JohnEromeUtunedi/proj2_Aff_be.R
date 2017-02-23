
# Read affirmative asylum data from csv file
data1 = read.csv("Project2/data/affirmative_asylum.csv", stringsAsFactors = FALSE)
data1 = tbl_df(data1[data1$Continent.Country.of.Nationality != "Total",])

#Format continental data
Cont_Aff_data = data1[1:7,]
Cont_Aff_data_row = nrow(Cont_Aff_data)
Cont_Aff_data_col = ncol(Cont_Aff_data)
Cont_Aff_data[,2:Cont_Aff_data_col] = lapply(Cont_Aff_data[,2:Cont_Aff_data_col], gsub, patt = ",", replacement = "")
Cont_Aff_data[,2:Cont_Aff_data_col] = lapply(Cont_Aff_data[,2:Cont_Aff_data_col], as.numeric)
Cont_Aff_data = melt(Cont_Aff_data, id = "Continent.Country.of.Nationality")                                                 
names(Cont_Aff_data) = c("Continent","Year","Affirmative.Asylum")
Cont_Aff_data[[2]] = substr(Cont_Aff_data[[2]],2,5)
Cont_Aff_data[,2] = as.numeric(Cont_Aff_data[,2])

#Format Country data
Country_Aff_data = data1[8:nrow(data1),]
Country_Aff_data_row = nrow(Country_Aff_data)
Country_Aff_data_col = ncol(Country_Aff_data)
Country_Aff_data[,2:Country_Aff_data_col] = lapply(Country_Aff_data[,2:Country_Aff_data_col], gsub, patt = ",", replacement = "")
Country_Aff_data[,2:Country_Aff_data_col] = lapply(Country_Aff_data[,2:Country_Aff_data_col], as.numeric)
Country_Aff_data[is.na(Country_Aff_data)] = 0
Country_Aff_data = melt(Country_Aff_data, id = "Continent.Country.of.Nationality")                                                 
names(Country_Aff_data) = c("Country","Year","Affirmative.Asylum")
Country_Aff_data[[2]] = substr(Country_Aff_data[[2]],2,5)
Country_Aff_data[2] = as.numeric(Country_Aff_data[,2])

#Identify map by country and continent
map.world.Aff = map_data(map = "world")
map.world.Aff = subset(map.world.Aff, region!="Antarctica")
Country_data_match_Aff = merge(Country_Aff_data, map.world.Aff, by.x = "Country", by.y = "region")
Country_data_match_Aff = arrange(Country_data_match_Aff, group, order)

# The purpose of this function is to plot
# a bar chart indicating the top/least 2-6 Continents
# from where affirmative asylees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
ContinentFilterBar_Aff.Plotly = function(data1 = Cont_Aff_data, fil = "2006", height = 2, arrange = 1) {
  if(arrange == 1) {
    temp = arrange(filter(data1, Year == fil),desc(Affirmative.Asylum))[1:height,]
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$Affirmative.Asylum)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Affirmative.Asylum, type = "bar", color = ~Continent,
                                  colors = 'Set2') %>% 
      layout(title = paste("Continents with largest amount of Affirmative Asylum Status in", fil), xaxis =list(title = ""), yaxis = list(title = "Affirmative Asylum"))
    
  }
  else {
    temp = arrange(filter(data1, Year == fil), Affirmative.Asylum)[1:height,] 
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(temp$Affirmative.Asylum)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Affirmative.Asylum, type = "bar", color = ~Continent,
                                  colors = 'Set2') %>%
      layout(title = paste("Continents with least amount of Affirmative Asylum Status in", fil), xaxis =list(title = ""), yaxis = list(title = "Affirmative Asylum total"))
    
  }
  return(val)
}

# The purpose of this function is to view the affirmative asylyees from each continent
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-6
# continents from which affirmative asylees come from
ContinentFilterTotal_Aff.Plotly = function(data = Cont_Aff_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Affirmative.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Continent)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Affirmative.Asylum, type = 'bar', color = ~Continent, 
            colors = 'Set2')
  } else {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Affirmative.Asylum, color = ~Continent, 
            size = ~Affirmative.Asylum, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Continents containing people with Affiramtive Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"), barmode = 'stack')
}

# The purpose of this function is to display the continents
# with the most affirmative asylees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-6 continets 
ContinentFilterSum_Aff.Plotly = function(data = Cont_Aff_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Affirmative.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, type = 'bar', color = I("blue"))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, color = ~Continent, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Top", amt, "Continents containing people with","<br />","Affiramtive Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"))
}

# The purpose of this function is to plot
# a bar chart indicating the top/least 2-10 Countries
# from where affirmative asylees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
CountryFilterBar_Aff.Plotly = function(data = Country_Aff_data, Year_val = 2006, height = 10, arrange = 1) {
  if(arrange == 1) {
    temp = arrange(filter(data, Year == Year_val, Affirmative.Asylum!=0), desc(Affirmative.Asylum))[1:height,]
    temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$Affirmative.Asylum)], ordered = TRUE)
    plot_ly(data = temp, x = ~Affirmative.Asylum, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',
            text = ~paste('Country:',Country), hoverinfo = 'all') %>%  
      layout(title = paste("Countries with Largest amount of Affirmative Asylum Status in", Year_val), xaxis =list(title = "Total Amount of Affirmative Asylum"), yaxis = list(title = "", tickangle = 70))    }
  else {
    temp = arrange(filter(data, Year == Year_val, Affirmative.Asylum!=0), Affirmative.Asylum)[1:height,]
    temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(temp$Affirmative.Asylum)], ordered = TRUE)
    plot_ly(data = temp, x = ~Defensive.Asylum, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',
            hoverinfo = 'all') %>% 
      layout(title = paste("Countries with smallest amount of Affiramtive Asylym Status in", Year_val), xaxis =list(title = "Total Amount of Affiramtive Asylum Status"), yaxis = list(title = "", tickangle = 70))
  }
}

# The purpose of this function is to view the affirmative asylees from each country
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-10
# countries from which affirmative asylees come from
CountryFilterTotal_Aff.Plotly = function(data = Country_Aff_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Affirmative.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Country)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Affirmative.Asylum, type = 'bar', color = ~Country,
                        colors = 'Accent')
  } else {
    temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Affirmative.Asylum, color = ~Country, colors = 'Accent',
            size = ~Affirmative.Asylum, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Countries containing people with Affirmative Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"), barmode = 'stack')
}

# The purpose of this function is to display the countries
# with the most affirmative asylees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-10 countries 
CountryFilterSum_Aff.Plotly = function(data = Country_Aff_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Affirmative.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, type = 'bar', color = I("blue"))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, color = ~Country, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Top", amt, "Countries containing people with Affirmative","<br />","Asylum status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"))
}

# The purpose of this function is to create a trend plot to allow the user
# to compare individual countries against the total affirmative asylees per year. 
# Used with shiny, the user can select multiple countries and compare them
# against the total affirmative asylees for each year
CountryFilterUsrInteract_Aff.Plotly = function(data = Country_Aff_data, var = "Nigeria") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Affirmative.Asylum))
  plot_ly() %>% add_trace(data = filter(data, Country %in% c(var)), x = ~Year, y = ~Affirmative.Asylum, color = ~Country, type = 'scatter', 
                          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>%
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"),
              line = list(width = 5, dash = 'dash', shape = 'spline')) %>% 
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"))
}

# The purpose of this function is to create a trend plot to allow the user
# to compare each continent against the total affirmative asylees per year.
# Used with shiny, the user can select multiple continents and compare them
# against the total affirmative asylees for each year
ContinentFilterUsrInteract_Aff.Plotly = function(data = Cont_Aff_data, var = "Africa") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Affirmative.Asylum))
  plot_ly() %>% add_trace(data = filter(data, Continent %in% c(var)), x = ~Year, y = ~Affirmative.Asylum, color = ~Continent, type = 'scatter', 
                          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>%
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"), 
              line = list(width = 5, dash = 'dash', shape = 'spline')) %>% 
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"))
}

# The purpose of this function is to create a bar plot to
# display the total affirmative asylees per year
Total_Aff.Plotly = function(data = Cont_Aff_data) {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Affirmative.Asylum))
  plot_ly() %>% add_trace(data =temp, x = ~Year, y = ~sum, name = "Total Affirmative Asylum", type = 'bar', color = ~sum, 
                          text = ~paste("Year:",Year,"<br />Total:",sum),hoverinfo = 'text',
                          colors = brewer.pal(9,'Reds'), marker = list(colorbar = list(title = "Affirmative Asylum Total"))) %>%
    layout(xaxis = list(title = ""), yaxis = list(title = "Affirmative Asylum Total"), paper_bgcolor = 'rgb(160,160,160)',
           plot_bgcolor = 'rgb(160,160,160)')
  
}
## 

