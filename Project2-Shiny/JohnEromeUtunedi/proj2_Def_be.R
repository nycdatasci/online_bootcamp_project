
# Read defensive asylum data from csv file
data2 = read.csv("Project2/data/defensive_asylum.csv", stringsAsFactors = FALSE)
data2 = tbl_df(data2[data2$Continent.Country.of.Nationality != "Total",])

#Format continental data
Cont_Def_data = data2[1:7,]
Cont_Def_data_row = nrow(Cont_Def_data)
Cont_Def_data_col = ncol(Cont_Def_data)
Cont_Def_data[,2:Cont_Def_data_col] = lapply(Cont_Def_data[,2:Cont_Def_data_col], gsub, patt = ",", replacement = "")
Cont_Def_data[,2:Cont_Def_data_col] = lapply(Cont_Def_data[,2:Cont_Def_data_col], as.numeric)
Cont_Def_data = melt(Cont_Def_data, id = "Continent.Country.of.Nationality")                                                 
names(Cont_Def_data) = c("Continent","Year","Defensive.Asylum")
Cont_Def_data[[2]] = substr(Cont_Def_data[[2]],2,5)
Cont_Def_data[2] = lapply(Cont_Def_data[2], as.numeric)

#Format Country Data
Country_Def_data = data2[8:nrow(data2),]
Country_Def_data_row = nrow(Country_Def_data)
Country_Def_data_col = ncol(Country_Def_data)
Country_Def_data[,2:Country_Def_data_col] = lapply(Country_Def_data[,2:Country_Def_data_col], gsub, patt = ",", replacement = "")
Country_Def_data[,2:Country_Def_data_col] = lapply(Country_Def_data[,2:Country_Def_data_col], as.numeric)
Country_Def_data[is.na(Country_Def_data)] = 0
Country_Def_data = melt(Country_Def_data, id = "Continent.Country.of.Nationality")                                            
names(Country_Def_data) = c("Country","Year","Defensive.Asylum")
Country_Def_data[[2]] = substr(Country_Def_data[[2]],2,5)
Country_Def_data[2] = lapply(Country_Def_data[2], as.numeric)

#Identify map by country and continent
map.world.Def = map_data(map = "world")
map.world.Def = subset(map.world.Def, region!="Antarctica")
Country_data_match_Def = merge(Country_Def_data, map.world.Def, by.x = "Country", by.y = "region")
Country_data_match_Def = arrange(Country_data_match_Def, group, order)

# The purpose of this function is to plot
# a bar chart indicating the top/least 2-6 Continents
# from where defensive asylees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
ContinentFilterBar_Def.Plotly = function(data1 = Cont_Def_data, fil = "2006", height = 2, arrange = 1) {
  if(arrange == 1) {
    temp = arrange(filter(data1, Year == fil),desc(Defensive.Asylum))[1:height,]
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$Defensive.Asylum)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Defensive.Asylum, type = "bar", color = ~Continent,
                                  colors = 'Set2') %>%
      layout(title = paste("Continents with largest amount of Defensive Asylum Status in", fil), xaxis =list(title = ""), yaxis = list(title = "Defensive Asylum"))
  }
  else {
    temp = arrange(filter(data1, Year == fil),Defensive.Asylum)[1:height,] 
    temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(temp$Defensive.Asylum)], ordered = TRUE)
    val = plot_ly() %>% add_trace(data = temp, x = ~Continent, y = ~Defensive.Asylum, type = "bar", color = ~Continent,
                                  colors = 'Set2') %>%
    layout(title = paste("Continents with least amount of Defensive Asylum Status in", fil), xaxis =list(title = ""), yaxis = list(title = "Defensive Asylum total"))
  }
  return(val)
}

# The purpose of this function is to view the defensive asylyees from each continent
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-6
# continents from which defensive asylees come from
ContinentFilterTotal_Def.Plotly = function(data = Cont_Def_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Defensive.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Continent)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Defensive.Asylum, type = 'bar', color = ~Continent, 
            colors = 'Set2')
  } else {
    temp_plot = plot_ly(data = filter(data, Continent %in% c(temp_list)), x = ~Year, y = ~Defensive.Asylum, color = ~Continent, 
            size = ~Defensive.Asylum, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Continents containing people with Defensive Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"), barmode = 'stack')
}

# The purpose of this function is to display the continents
# with the most defensive asylees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-6 continets 
ContinentFilterSum_Def.Plotly = function(data = Cont_Def_data, amt = 2, type = 1) {
  temp = data %>% group_by(Continent)  %>% summarise(sum = sum(Defensive.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Continent = factor(as.factor(temp$Continent), levels = as.factor(temp$Continent)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, type = 'bar', color = I('blue'))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Continent, y = ~sum, color = ~Continent, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) }
  temp_plot %>% layout(title = paste("Top", amt, "Continents containing people with","<br />","Defensive Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"))
}

# The purpose of this function is to plot
# a bar chart indicating the top/least 2-10 Countries
# from where defensive asylees come from
# based on the year selected by the user.
# This function will also allow the bar plots 
# to be shown in ascending or descending order
CountryFilterBar_Def.Plotly = function(data = Country_Def_data, Year_val = 2006, height = 10, arrange = 1) {
  if(arrange == 1) {
    temp = arrange(filter(data, Year == Year_val, Defensive.Asylum!=0), desc(Defensive.Asylum))[1:height,]
    temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$Defensive.Asylum)], ordered = TRUE)
    plot_ly(data = temp, x = ~Defensive.Asylum, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',
            text = ~paste('Country:',Country), hoverinfo = 'all') %>%  
      layout(title = paste("Countries with Largest amount of Defensive Asylum Status in", Year_val), xaxis =list(title = "Total Amount of Defensive Asylum Status"), yaxis = list(title = "", tickangle = 70)) }
  else {
    temp = arrange(filter(data, Year == Year_val, Defensive.Asylum!=0), Defensive.Asylum)[1:height,]
    temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(temp$Defensive.Asylum)], ordered = TRUE)
    plot_ly(data = temp, x = ~Defensive.Asylum, y = ~Country, type = 'bar', color = ~Country, colors = 'BrBG',
            hoverinfo = 'all') %>% 
      layout(title = paste("Countries with smallest amount of Defensive Asylym Status in", Year_val), xaxis =list(title = "Total Amount of Defensive Asylum Status"), yaxis = list(title = "", tickangle = 70))
    
  }
}

# The purpose of this function is to view the defensive asylees from each country
# on a yearly basis. Used with shiny, the user will also be able to decide
# if he want to view plot using a bar plot or a bubble plot and the top 2-10
# countries from which defensive asylees come from
CountryFilterTotal_Def.Plotly = function(data = Country_Def_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Defensive.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp_list = as.list(temp$Country)
  if(type == 1) {
    temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Defensive.Asylum, type = 'bar', color = ~Country, 
                        colors = 'Accent')
  } else {
    temp_plot = plot_ly(data = filter(data, Country %in% c(temp_list)), x = ~Year, y = ~Defensive.Asylum, color = ~Country, colors = 'Accent', 
            size = ~Defensive.Asylum, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Breakdown of top", amt, "Countries containing people with Defensive Asylum Status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"), barmode = 'stack')
}

# The purpose of this function is to display the countries
# with the most defensive asylees from 2006-2015 in descending order.
# Used with shiny, the user will be able to select the
# top 2-10 countries 
CountryFilterSum_Def.Plotly = function(data = Country_Def_data, amt = 5, type = 1) {
  temp = data %>% group_by(Country)  %>% summarise(sum = sum(Defensive.Asylum)) %>% arrange(desc(sum))
  temp = temp[1:amt,]
  temp$Country = factor(as.factor(temp$Country), levels = as.factor(temp$Country)[order(-temp$sum)], ordered = TRUE)
  if(type == 1) {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, type = 'bar', color = I("blue"))
  } else {
    temp_plot = plot_ly(data = temp, x = ~Country, y = ~sum, color = ~Country, 
            size = ~sum*10, type = "scatter",mode = "markers", marker = list(sizemode = 'diameter', opacity = 0.75)) 
  }
  temp_plot %>% layout(title = paste("Top", amt, "Countries containing people with","<br />","Defensive Asylum status from 2006-2015"),
                       xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"))
}

# The purpose of this function is to create a trend plot to allow the user
# to compare individual countries against the total defensive asylees per year. 
# Used with shiny, the user can select multiple countries and compare them
# against the total defensive asylees for each year
CountryFilterUsrInteract_Def.Plotly = function(data = Country_Def_data, var = "Nigeria") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Defensive.Asylum))
  plot_ly() %>% add_trace(data = filter(data, Country %in% c(var)), x = ~Year, y = ~Defensive.Asylum, color = ~Country, type = 'scatter', 
                          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>%
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"), line = list(width = 5,dash = 'dash', shape = 'spline')) %>%
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"))
  }

# The purpose of this function is to create a trend plot to allow the user
# to compare each continents against the total defensive asylees per year.
# Used with shiny, the user can select multiple continents and compare them
# against the total affirmative asylees for each year
ContinentFilterUsrInteract_Def.Plotly = function(data = Cont_Def_data, var = "Africa") {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Defensive.Asylum))
  plot_ly() %>% add_trace(data = filter(data, Continent %in% c(var)), x = ~Year, y = ~Defensive.Asylum, color = ~Continent, type = 'scatter', 
                          mode = 'lines', colors = "Set1", line = list(width = 5, shape = 'spline')) %>%
    add_trace(data = temp, x = ~Year, y = ~sum, type = 'scatter', mode = 'lines', name = 'Total', color = I("black"), line = list(width = 5, dash = 'dash', shape = 'spline')) %>% 
    layout(title = '', xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"))
}

# The purpose of this function is to create a bar plot to
# display the total defensive asylees per year
Total_Def.Plotly = function(data = Cont_Def_data) {
  temp = data %>% group_by(Year) %>% summarise(sum = sum(Defensive.Asylum))
  plot_ly() %>% add_trace(data =temp, x = ~Year, y = ~sum, type = 'bar', name = "Total Defensive Asylum",color = ~sum, 
                          text = ~paste("Year:",Year,"<br />Total:",sum),hoverinfo = 'text',
                          colors = brewer.pal(9,'Reds'),marker = list(colorbar = list(title = "Defensive Asylum Total"))) %>% 
    layout(xaxis = list(title = ""), yaxis = list(title = "Defensive Asylum Total"), paper_bgcolor = 'rgb(160,160,160)',
           plot_bgcolor = 'rgb(160,160,160)')
}
## 



