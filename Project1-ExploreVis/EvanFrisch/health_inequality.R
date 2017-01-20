#install.packages("dplyr")
library(dplyr)

#Convenience function for saving graphs consistently
savegraph <- function(graphname) {
  ggsave(graphname, file = paste0(deparse(substitute(graphname)),".png"), width = 10, height = 8, dpi = 200)
}

# Read in Online Table 1 (Life Expectancy by Household Income and Gender, pooling years 2000 - 2014)
download.file("https://healthinequality.org/dl/health_ineq_online_table_1.csv", "healthinequality1.csv", method = "auto")

table1 <- read.csv("healthinequality1.csv")

table1$gnd <- ifelse(table1$gnd == "F","Female","Male")
table1 <- mutate(table1,log.hh_inc = log10(hh_inc))

#install.packages("ggplot2")
library(ggplot2)

graph1 <- ggplot(table1, aes(x = hh_inc, y = le_raceadj)) + geom_point(aes(color = gnd)) + 
  labs(x = "Household Income", y = "Life Expectancy\n(Race-Adjusted)",
       title = "U.S. Life Expectancy Estimates by Household Income and Gender",
       subtitle = "(Data pooled for 2001 to 2014)",
       color = "Gender") +
  scale_x_continuous(labels = scales::dollar) +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

graph1

savegraph(graph1)

graph2 <- ggplot(table1, aes(x = hh_inc, y = le_raceadj)) + geom_point(aes(color = gnd)) +
  labs(x = "Household Income", y = "Life Expectancy\n(Race-Adjusted)",
       title = "U.S. Life Expectancy Estimates by Household Income (Log) and Gender",
       subtitle = "(Data pooled for 2001 to 2014)",
       color = "Gender") +
  scale_x_log10(labels = scales::dollar, breaks = c(1E3,1E4,1E5,1E6)) +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

graph2
savegraph(graph2)

# Read in Online Table 3 (State-Level Life Expectancy by Household Income Quartile and Gender)
download.file("https://healthinequality.org/dl/health_ineq_online_table_3.csv", "healthinequality3.csv", method = "auto")

table3 <- read.csv("healthinequality3.csv")

#Set region for each state based on Census Bureau regions
table3 <- mutate(table3, region = ifelse(stateabbrv %in% c("CT","ME","MA","NH","RI","VT","NJ","NY","PA"),"Northeast",
                                        ifelse(stateabbrv %in% c("ND","MN","SD","NE","IA","KS","MO","WI","MI","IL","IN","OH"), "Midwest",
                                             ifelse(stateabbrv %in% c("AZ","CO","ID","MT","WY","NV","UT","NM","WA","OR","CA","HI","AK"), "West","South"))))

#install.packages("ggrepel")
library(ggrepel)

#Isolate one state to annotate on graph
example.state.f <- filter(table3, stateabbrv == 'HI')
example.state.disparity.f <- round(example.state.f$le_raceadj_q4_F - example.state.f$le_raceadj_q1_F, digits = 1)
example.state.annotation.f <- "For each state, height above\ndiagonal line equals disparity\nin years of life expectancy\nbetween women of high and\nlow household incomes."
example.state.annotation.f <- paste0(example.state.annotation.f,"\n\nFor ",example.state.f$statename," this is ",as.character(example.state.disparity.f)," years.")
 
graph3 <- ggplot(table3, aes(x = le_raceadj_q1_F, y = le_raceadj_q4_F, color = region)) + 
  geom_point(size=1.75) +
  scale_color_manual(name = "Region", breaks = c("Northeast","South","Midwest","West"), values = c("blue","red","yellow","green")) +
  geom_segment(data = example.state.f, color = "black", aes(xend = le_raceadj_q1_F, yend = le_raceadj_q1_F), linetype = 5, size = 0.25) +
  geom_label(data = example.state.f, 
             size = 3,
             aes(label = example.state.annotation.f),
             nudge_x = 0.8, nudge_y = -1.5, color = "black") +
  labs(x = "Life Expectancy (Race-Adjusted) for Quartile 1 Household Income", y = "Life Expectancy (Race-Adjusted) for Quartile 4 Household Income",
       title = "State-Level Female Life Expectancy by Household Income Quartile") +
  coord_cartesian(xlim = c(80,86), ylim = c(80,90)) +
  geom_abline(intercept = 0, slope = 1) +
  geom_label_repel(aes(label = stateabbrv), size = 3, nudge_x = 0.05, color = "black", segment.color = "#333333", segment.alpha = 0.5, 
       segment.size = 0.3, arrow = arrow(length = unit(0.01, 'npc')), point.padding = unit(1, 'lines'), force = 0.25) +
  scale_x_continuous(limits = c(80,86),breaks = seq(80,86,1)) +
  scale_y_continuous(limits = c(80,90),breaks = seq(80,90,1)) +
  theme(plot.title = element_text(hjust = 0.5))

graph3

savegraph(graph3)

example.state.m <- filter(table3, stateabbrv == 'IN')
example.state.disparity.m <- round(example.state.m$le_raceadj_q4_M - example.state.m$le_raceadj_q1_M, digits = 1)
example.state.annotation.m <- "For each state, height above\ndiagonal line equals disparity\nin years of life expectancy\nbetween men of high and\nlow household incomes."
example.state.annotation.m <- paste0(example.state.annotation.f,"\n\nFor ",example.state.f$statename," this is ",as.character(example.state.disparity.f)," years.")

graph4 <- ggplot(table3, aes(x = le_raceadj_q1_M, y = le_raceadj_q4_M)) + 
  geom_point() +
  geom_segment(data = example.state.m, aes(xend = le_raceadj_q1_M, yend = le_raceadj_q1_M), linetype = 5, size = 0.25) +
  geom_label(data = example.state.m, 
             aes(label = example.state.annotation.m),
             nudge_x = 1, nudge_y = -4.5) +  
  labs(x = "Life Expectancy (Race-Adjusted) for Quartile 1 Household Income", y = "Life Expectancy (Race-Adjusted) for Quartile 4 Household Income",
       title = "State-Level Male Life Expectancy by Household Income Quartile") +
  coord_cartesian(xlim = c(74,81), ylim = c(74,87)) +
  geom_abline(intercept = 0, slope = 1) +
  geom_label_repel(aes(label = stateabbrv), size = 3.5, hjust = 0, nudge_x = 0.05, segment.color = "#333333", segment.alpha = 0.5, 
      segment.size = 0.3, arrow = arrow(length = unit(0.01, 'npc')), point.padding = unit(1, 'lines'), force = 0.25) +
  scale_x_continuous(limits = c(74,81),breaks = seq(74,81,1)) +
  scale_y_continuous(limits = c(74,88),breaks = seq(74,88,1)) +
  theme(plot.title = element_text(hjust = 0.5))

graph4

savegraph(graph4)

table3 <- mutate(table3,state.capitalized = toupper(statename))
table3 <- mutate(table3, q4to1.le.diff.f = le_raceadj_q4_F - le_raceadj_q1_F)
table3 <- mutate(table3, q4to1.le.diff.m = le_raceadj_q4_M - le_raceadj_q1_M)

#install.packages("mapproj")
library(mapproj)
#install.packages("maps")
library(maps)
#install.packages("fiftystater")
library(fiftystater)

states <- map_data("state")
states <- mutate(states,state.capitalized = toupper(region))

table3.no.DC <- filter(table3,stateabbrv != "DC")

legend_title <- "Added Years"

row.names(table3.no.DC) <- tolower(table3.no.DC$statename)
table3.no.DC <- mutate(table3.no.DC,state = tolower(statename))

graph5 <- ggplot(table3.no.DC, aes(map_id = state)) + 
  geom_map(aes(fill =  q4to1.le.diff.f), map = fifty_states,color="black") + 
  expand_limits(x = fifty_states$long, y = fifty_states$lat) +
  coord_map() +
  scale_x_continuous(breaks = NULL) + 
  scale_y_continuous(breaks = NULL) +
  labs(x = "", y = "") +
  theme(legend.position = "bottom", 
        panel.background = element_blank(),
        plot.title = element_text(hjust = 0.5)) + 
  labs(title = "Added Years of Female Life Expectancy (Race-Adjusted)\nFor Quartile 4 over Quartile 1 Household Income") +
  scale_fill_gradient(name = legend_title, low = "yellow", high = "red")

graph5 + fifty_states_inset_boxes() 

savegraph(graph5)

graph6 <- ggplot(table3.no.DC, aes(map_id = state)) + 
  geom_map(aes(fill =  q4to1.le.diff.m), map = fifty_states,color="black") + 
  expand_limits(x = fifty_states$long, y = fifty_states$lat) +
  coord_map() +
  scale_x_continuous(breaks = NULL) + 
  scale_y_continuous(breaks = NULL) +
  labs(x = "", y = "") +
  theme(legend.position = "bottom", 
        panel.background = element_blank(),
        plot.title = element_text(hjust = 0.5)) + 
  labs(title = "Added Years of Male Life Expectancy (Race-Adjusted)\nFor Quartile 4 over Quartile 1 Household Income") +
  scale_fill_gradient(name = legend_title, low = "yellow", high = "red")

graph6 + fifty_states_inset_boxes() 

savegraph(graph6)

# Read in Online Table 2 (National By-Year Life Expectancy by Percentile and Gender)
download.file("https://healthinequality.org/dl/health_ineq_online_table_2.csv", "healthinequality2.csv", method = "auto")
table2 <- read.csv("healthinequality2.csv")

table2.reduced <- filter(table2, pctile %in% c(25,75)) %>% select(gnd,pctile,year,hh_inc,le_raceadj)

table2.reduced.f.25percentile <- filter(table2.reduced, pctile == 25 & gnd == "F") %>% rename(hh_inc.25per.f = hh_inc, le_raceadj.25per.f = le_raceadj) %>% select(-gnd,-pctile) 
table2.reduced.f.75percentile <- filter(table2.reduced, pctile == 75 & gnd == "F") %>% rename(hh_inc.75per.f = hh_inc, le_raceadj.75per.f = le_raceadj) %>% select(-gnd,-pctile) 

table2.reduced.m.25percentile <- filter(table2.reduced, pctile == 25 & gnd == "M") %>% rename(hh_inc.25per.m = hh_inc, le_raceadj.25per.m = le_raceadj) %>% select(-gnd,-pctile) 
table2.reduced.m.75percentile <- filter(table2.reduced, pctile == 75 & gnd == "M") %>% rename(hh_inc.75per.m = hh_inc, le_raceadj.75per.m = le_raceadj) %>% select(-gnd,-pctile) 

table2.4series <- inner_join(table2.reduced.f.25percentile, table2.reduced.f.75percentile, by="year") %>%
  inner_join(., table2.reduced.m.25percentile, by = "year") %>% inner_join(., table2.reduced.m.75percentile, by = "year")


graph7 <- ggplot(table2.4series, aes(x = year)) + geom_line(aes(y = le_raceadj.75per.f, color = "Female, 75th")) +
  geom_line(aes(y = le_raceadj.25per.f, color = "Female, 25th")) + 
  geom_line(aes(y = le_raceadj.75per.m, color = "Male, 75th")) +
  geom_line(aes(y = le_raceadj.25per.m, color = "Male, 25th")) +
  scale_color_manual(name="Gender and Household Income Percentile",
                     breaks = c("Female, 75th", "Female, 25th", "Male, 75th", "Male, 25th"),
                     values = c("Female, 75th" = "#8B0000", "Female, 25th" = "#FFB6C1",
                                "Male, 75th" = "#0000A0", "Male, 25th" = "#00FFFF")) +
  geom_ribbon(aes(ymin=le_raceadj.25per.f, ymax=le_raceadj.75per.f, x=year, fill = "Female"), alpha = 0.2) +
  geom_ribbon(aes(ymin=le_raceadj.25per.m, ymax=le_raceadj.75per.m, x=year, fill = "Male"), alpha = 0.2) +
  scale_fill_manual(name = "Life Expectancy Gap",values = c("#D490AF","#9390D4")) +
  scale_x_continuous(name = "Year",limits = c(2000,2015),breaks = seq(2000,2014,2)) +
  scale_y_continuous(name = "Life Expectancy\n(Race-Adjusted)",limits = c(77,90),breaks = seq(77,90,2)) +
  labs(title = "U.S. Life Expectancy Estimates by Gender and Income Percentile",
       subtitle = "By Year from 2001 to 2014") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))

graph7

savegraph(graph7)
s
