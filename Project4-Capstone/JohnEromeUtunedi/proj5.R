library(DBI)
library(RSQLite)
library(data.table)
library(plotly)
library(dplyr)
library(corrplot)
library(xgboost)
library(Matrix)
library(RColorBrewer)
library(nnet)
library(randomForest)
library(e1071)
library(MASS)
library(caret)
library(dummies)
library(VIM)
library(neuralnet)

load('proj5.RData')
load('proj5.Rhistory')
history("proj5.Rhistory")
save.image(file = "proj5.RData")

con = dbConnect(drv = SQLite(),dbname  = "database.sqlite")
alltables = dbListTables(con)
Country.table = as.data.table(dbGetQuery(con,'select * from Country'))
League.table = as.data.table(dbGetQuery(con,'select * from League'))
Match.table = as.data.table(dbGetQuery(con,'select * from Match'))
Player.table = as.data.table(dbGetQuery(con,'select * from Player'))
Player.Attributes.table = as.data.table(dbGetQuery(con,'select * from Player_Attributes'))
Team.table = as.data.table(dbGetQuery(con,'select * from Team'))
Team.Attributes.table = as.data.table(dbGetQuery(con,'select * from Team_Attributes'))

#Need to create a single table of just home and away team real names just to know which team the match
# is referring to then need to start eliminating variables that will not be conducive to the algorithms.
#Also need to start data visualization

###############################################
#Data Visualization
###############################################
summary(Team.table)
summary(Match.table)
View(Team.table)
View(Match.table)
View(Player.Attributes.table)
View(Player.table)
str(Team.table)
str(Match.table)
#Need to get rid of the following columns since they add no value:
#home_player_X#, away_player_Y#, home_player_Y#, away_player_Y#,
#goal, shoton, shutoff, foulcommit, card, cross, corner, posession
#The home_player_X#, etc are duplicates and the rest of the columns
#were not properly inserted in the sqlite table. Given time, I will go
#back to see if I can extract the correct information from them
#*************************************
#Match Table Data Munging
#*************************************
rm.frm.match.table = c()
for (i in 1:44){
    if (i <= 11){
        rm.frm.match.table[i] = paste0('home_player_X',i)
    }
    else if (i > 11 &  i <= 22){
        rm.frm.match.table[i] = paste0('away_player_X',i-11)
    }    
    else if (i > 22 &  i <= 33){
        rm.frm.match.table[i] = paste0('home_player_Y',i-22)
    } 
    else if (i > 33 &  i <= 44){
        rm.frm.match.table[i] = paste0('away_player_Y',i-33)
    }
    else{  }
}
rm.frm.match.table = append(rm.frm.match.table, c('goal','shoton','shotoff',
                                                  'foulcommit','card','cross','corner','possession'))
rm.frm.match.table
Match.table.updated = copy(Match.table)
Match.table.updated = Match.table.updated[,-c(rm.frm.match.table),with = FALSE]

names(Match.table.updated)
summary(Match.table.updated)
View(Match.table.updated)
dim(Match.table.updated)

summary(Match.table.updated[,.(home_team_goal,away_team_goal)])
#As you can see above, each match has a score, so we need to figure out a 
#way to replace NAs especially for the betting. 
#Look at distribution of betting data and see if it should be replaced by Mean or Median
#value of column. Not the best representation though since teams that are obviously superior
#than other teams will have the same betting chance
summary(Match.table.updated[,.(country_id, league_id, season, stage, date, match_api_id)])
summary(Match.table.updated[,.(home_team_api_id, away_team_api_id, home_team_goal, away_team_goal)])
summary(Match.table.updated[,.(home_player_1, home_player_2, home_player_3, home_player_4,
                                  home_player_5, home_player_6, home_player_7, home_player_8,
                                  home_player_9, home_player_10, home_player_11)])
View(Match.table.updated[,.(home_player_1, home_player_2, home_player_3, home_player_4,
                               home_player_5, home_player_6, home_player_7, home_player_8,
                               home_player_9, home_player_10, home_player_11)], 
     title = "Match.Table.Updated.HomePlayers")
#Need to remove observations where all players have NA for identification. If only a few is missing
#from that observation, replace player attributes with average of the other players
summary(Match.table.updated[,list(away_player_1, away_player_2, away_player_3, away_player_4,
                                  away_player_5, away_player_6, away_player_7, away_player_8,
                                  away_player_9, away_player_10, away_player_11)])
View(Match.table.updated[,list(away_player_1, away_player_2, away_player_3, away_player_4,
                               away_player_5, away_player_6, away_player_7, away_player_8,
                               away_player_9, away_player_10, away_player_11)],
     title = "Match.Table.Updated.AwayPlayers")
#Need to remove observations where all players have NA for identification. If only a few is missing
#from that observation, replace player attributes with average of the other players

betting = c('B365H','B365A','B365D','BWH','BWD','BWA','IWH','IWA','IWD','LBH','LBD','LBA','PSH','PSD','PSA',
            'WHH','WHD','WHA','SJH','SJD','SJA','VCH','VCD','VCA','GBH','GBD','BSH','BSD','BSA')

summary(Match.table.updated[,c(betting),with=FALSE])

home.away = c()
for (i in 1:22){
    if (i <= 11){
        home.away[i] = paste0('home_player_',i)
    }
    else{
        home.away[i] = paste0('away_player_',i-11)
    }
    
}
t_ = copy(Match.table.updated)
#Checking each betting column to see 
#if it contains any NA and if it does, then 
#you remove the rows with NAs in them. This is done to
#identify how many rows would be left if all the rows with
#NAs were taken out due to NAs from the betting columns.
#I am sure there is a better way to write this. 
dim(t_[complete.cases(t_[,.SD,.SDcols = c(betting,home.away)]),])

#Find correlation between Betting variables 

corrplot(cor(Match.table.updated[,c(betting),with = FALSE], use = "na.or.complete"), method = 'square',type = 'upper')
#Is it possible to get rid of the remaining betting columns since they provide the same information?
#Yes it is, select only the B365H,B365A,B365D 
#*******************************************
#Team Attributes Data Munging
#******************************************
summary(Team.Attributes.table)
summary(Team.table)
View(Team.Attributes.table)
View(Team.table)
team.attr.names = names(Team.Attributes.table)[lapply(Team.Attributes.table,class)=="integer"] 
team.attr.names = team.attr.names[!team.attr.names %in% c("id","team_fifa_api_id","team_api_id")]
team.attr.names
#BuildupPlayDribbling seams to be the only feature with NAs so will drop it
corrplot(cor(Team.Attributes.table[,.SD,.SDcols = c(team.attr.names)], use = 'na.or.complete'),
         method = 'color',type = 'upper')
t1_ = copy(Team.Attributes.table)
dim(t1_[complete.cases(t1_[,.SD,.SDcols = c(team.attr.names)]),])
dim(t1_)
summary(t1_)
#View(t1_)

#BuildupPlayDribbling has most of the missing data in this dataset, so look at the dataset
#without this feature to see if corrolation plot differs
corrplot(cor(Team.Attributes.table[,.SD,.SDcols = c(team.attr.names[!team.attr.names %in% c("buildUpPlayDribbling")])], 
             use = 'na.or.complete'),
         method = 'color',type = 'upper')
#*******************************************
#Player Attributes Data Munging
#******************************************
summary(Player.table)
summary(Player.Attributes.table)
dim(Player.Attributes.table)
#Some NAs but lets look at correlation plot to see which variables correlate with each other
#in order to see which ones to drop
t2_ = copy(Player.Attributes.table)
player.attr.name = names(Player.Attributes.table)[lapply(Player.Attributes.table,class)=="integer"]
player.attr.name = player.attr.name[!player.attr.name %in% c("id","player_fifa_api_id","player_api_id","date")]
player.attr.name
corrplot(cor(t2_[,.SD,.SDcols = c(player.attr.name)], use = 'complete.obs'),
         method = 'color', type = 'upper')
dim(Player.Attributes.table)
dim(t2_[complete.cases(t2_[,.SD,.SDcols = c(player.attr.name)]),])
dim(t2_)
summary(t2_)

############################################################
#Merge all Data Into One Table
############################################################

Main.Table = copy(Match.table.updated)
Main.Table[,date_update:=substr(date,1,4)]
Main.Table = merge(Main.Table,Team.table[,list(team_api_id,HomeTeam = team_long_name)],by.x = "home_team_api_id", 
                   by.y = "team_api_id", all.x = TRUE)
View(Main.Table)
Main.Table = merge(Main.Table,Team.table[,list(team_api_id,AwayTeam = team_long_name)],by.x = "away_team_api_id", 
                   by.y = "team_api_id", all.x = TRUE)
View(Main.Table)
summary(Main.Table)

##Fix Dates so that Team Ratings match per year
#You will probably still have NAs for anything less than
#2010 for the merged table containing team attributes so youll want
#to replace NAs of anything less than 2010 with the 2010 values
addTeamAttributes.Home.Away = function(val = 'Home',Main = Main.Table, Att.Table = Team.Attributes.table){
    Att.Table = copy(Att.Table)
    Main = copy(Main)
    Att.Table[,date_update:=substr(date,1,4)]
    Att.Table = Att.Table[,-c("id","date","team_fifa_api_id"),with = FALSE]
    #Att.Table = Att.Table[,-c('team_fifa_api_id','date'),with = FALSE]
    old.name = names(Att.Table)[!names(Att.Table) %in% c("team_api_id","date_update")]
    if(val == "Home"){
        new.name = paste0('Home_',old.name)
        col.name = "home_team_api_id"
    }
    else{
        new.name = paste0('Away_',old.name)
        col.name = "away_team_api_id"
    }
    
    Main = merge(Main,Att.Table,
                 by.x = c(col.name,"date_update"), by.y = c("team_api_id","date_update"), all.x = TRUE)
    setnames(Main,old.name,new.name)
    
    return(Main)
}

Main.Table.All = addTeamAttributes.Home.Away(val = "Home",Main = Main.Table, Att.Table = Team.Attributes.table)
Main.Table.All = addTeamAttributes.Home.Away(val = "Away",Main = Main.Table.All, Att.Table = Team.Attributes.table)
View(Main.Table.All)

#For players that have multiple ratings for the same year,
#select only the most current rating for that year
Player.Att.Table = copy(Player.Attributes.table)
Player.Att.Table[, date:= lapply(.SD, substr, 1, 4), .SDcols = c("date")]
Player.Att.Table[, date:= lapply(.SD, as.numeric), .SDcols = c("date")]
Player.Att.Table = Player.Att.Table %>%
    group_by(player_api_id,date) %>%
    arrange(desc(date)) %>%
    filter(row_number()==1)
dim(Player.Att.Table)
View(Player.Att.Table)

##Need to create a function with forloop, iterating through every column with Home and Away Team
#stats. If 2008 data is not available and 2009 is, replace 2008 with 2009, etc
#If 2009 data is not available and 2008 is, replace 2009 with 2008, etc

updateTeamRating = function(mainTable = Main.Table.All, type = "home_team_api_id"){
    mainTable = copy(mainTable)
    j.val = c()
    if (substr(type,1,4)=="home"){
        h_names = c(names(mainTable)[67:87])
    }else{
        h_names = c(names(mainTable)[88:108])
    }
    #h_names = "Home_buildUpPlaySpeed"
    j.val = append(2016:2008,2008:2016)
    subst1 = mainTable[,type,with = FALSE]
    count = 0
    for(i in unique(sort(as.numeric(mainTable[,.SD,.SDcols = type][[1]]))) ){
        for (k in h_names){
            for(j in c(1:length(j.val))){
                yr = j.val[j]
                if (as.character(j.val[j]) %in% mainTable[as.vector(subst1==i),date_update]){
                    while(any(is.na(mainTable[as.vector(subst1==i) & date_update == as.character(j.val[j]), k, with = FALSE])) 
                         & yr >= 2008 & yr <= 2016){
                        yr.string = as.character(yr)
                        mainTable[as.vector(subst1==i) & date_update == as.character(j.val[j]), c(k):=
                                lapply(mainTable[as.vector(subst1==i) & date_update == as.character(j.val[j]),c(k), with = FALSE]
                                       , function(x){ifelse(any(is.na(x)), mainTable[as.vector(subst1==i) & date_update == yr.string,
                                                                               k, with = FALSE][[1]][1],x)}), with = FALSE]
                        if(j <= 9){
                            yr = yr - 1;
                        }
                        else{
                            yr = yr + 1
                        }
                    }
                } else{
                }
            }
        }
        print(paste("Year:",j.val[j],k,"Home Team ID: ",i))
    }
    
    return(mainTable)
}

#updateTeamRating()
temp = updateTeamRating()
View(temp)

View(Main.Table.All)
View(Main.Table.All[which(is.na(Main.Table.All[,Home_buildUpPlaySpeed])) & date_update=="2008",])

T4_ = updateTeamRating(type = "home_team_api_id")
T4_ = updateTeamRating(mainTable = T4_, type = "away_team_api_id")
summary(T4_)
View(T4_)

####################################
#Lots of important variables but for now
#lets take only the overall player rating for each of the
#11 players and merge to main table
######################################
AddPlayerAttributes = function(main.table = T4_, player.table = Player.Attributes.table, type = "Home"){
    if(type == "Home"){
        home.away = names(main.table)[13:23]
    }
    else{
        home.away = names(main.table)[24:34]
    }
    
    main.table = copy(main.table)
    player.table = copy(player.table)
    new.player.table = data.table(Date = as.character(player.table$date), Player.ID = player.table$player_api_id, 
                                  Player.Rating = player.table$overall_rating) 
    # new.player.table = data.table(Date = substr(player.table$date, 1, 4), Player.ID = player.table$player_api_id, 
    #                               Player.Rating = player.table$overall_rating) 
    new.player.table = new.player.table[, list(Player.Rating  = mean(Player.Rating, na.rm = TRUE)), by = c("Date","Player.ID")]
    summary(new.player.table)
    new.name.vector = c()
    for (i in c(1:length(home.away)) ){
        main.table = merge(main.table, new.player.table, by.x = c(home.away[i],"date_update"), 
                           by.y = c("Player.ID", "Date"), all.x = TRUE)
        new.name = paste0(type,".Player.Rating.",i)
        new.name.vector[i] = new.name
        setnames(main.table,"Player.Rating",new.name)
        
    }
    #return(print(length(new.name.vector)))
    #return(print(paste(length(home.away),"Length of new.name.vector:",length(new.name.vector))))
    
    #Check if a home/away player has an ID for years 2008-2016
    #If he does then run a while loop that finds closest 
    #available rating to a NA and replace the NA with it.
    j.val = c(2016:2008,2008:2016)
    #j.val = append(2016:2008,2008:2016)
    #subst1 = mainTable[,type,with = FALSE]
    count = 0
    for(i in sort(unique( new.player.table[,Player.ID])) ){
        for (k in seq(to = length(home.away))){
            for(j in seq(to = length(j.val))){
                yr = j.val[j]
                subst1 = main.table[,.SD,.SDcols = home.away[k]]
                #subst2 = main.table[,.SD,.SDcols = new.name[k]]
                if (as.character(j.val[j]) %in% main.table[as.vector(subst1==i),date_update]){
                    while(any(is.na(main.table[as.vector(subst1==i) & date_update == as.character(j.val[j]), .SD, .SDcols = new.name.vector[k]])) 
                          & yr >= 2008 & yr <= 2016){
                        yr.string = as.character(yr)
                        # main.table[as.vector(subst1==i) & date_update == as.character(j.val[j]), new.name.vector[k] :=
                        #               lapply(main.table[as.vector(subst1==i) & date_update == as.character(j.val[j]), new.name.vector[k], with = FALSE]
                        #                      , function(x){ifelse(any(is.na(x)), main.table[as.vector(subst1==i) & date_update == yr.string,
                        #                                                                    new.name.vector[k], with = FALSE][[1]][1],x)})]
                        main.table[as.vector(subst1==i) & date_update == as.character(j.val[j]), new.name.vector[k] :=
                                       lapply(main.table[as.vector(subst1==i) & date_update == as.character(j.val[j]), new.name.vector[k], with = FALSE]
                                              , function(x){ifelse(any(is.na(x)), new.player.table[Player.ID == i & Date == yr.string,
                                                                                                   Player.Rating][1],x)})]
                        if(j <= 9){
                            yr = yr - 1;
                        }
                        else{
                            yr = yr + 1
                        }
                    }
                } else{
                }
            }
        }   
        print(paste("Year:",j.val[j],new.name.vector[k],type,"Player ID: ",i))
    }
    return(main.table)
}

T5_ = AddPlayerAttributes(main.table = T4_, type = "Home", player.table = Player.Att.Table)
View(T5_)
summary(T5_)
dim(T5_)
T6_ = AddPlayerAttributes(main.table = T5_, type = "Away", player.table = Player.Att.Table)
summary(T6_)
View(T6_[,67:130, with = FALSE])
View(T6_)

#Remove all bettings except B356H, B365D, B365A
T7_ = T6_[,append(1:37,65:130),with = FALSE]
summary(T7_)
View(T7_[,38:103, with = FALSE])
View(T7_[,1:37, with = FALSE])
##If teams are missing player attributes, either take average of all
#available players and replace with NA or replace by team average

#Replace NAs in team for overall team player average
setAllPlayerRatings = function(dataset = T7_){
    dataset = copy(dataset)
    home.away.player.rating.name = names(dataset)[82:103]
    for (i in c(1:dataset[,.N]) ){
        for (j in home.away.player.rating.name){
            dataset[i, (j) := lapply(.SD, function(x)
                {ifelse(is.na(x) & substr(j,1,4) == "Home",
                        rowMeans(dataset[i,.SD,.SDcols = home.away.player.rating.name[1:11]],
                                                                    na.rm = TRUE),
                        ifelse(is.na(x) & substr(j,1,4) == "Away", 
                               rowMeans(dataset[i,.SD,.SDcols = home.away.player.rating.name[12:22]],
                                                                            na.rm = TRUE),
                               x))}), .SDcols = j, with = FALSE]
            print(paste(i,dataset[i,.SD,.SDcols = j]))
        }
    }
    return(dataset)
}

T8_ = setAllPlayerRatings(dataset = T7_)
summary(T8_)
View(T8_)

#Now drop all the columns/features that will be useless for algorithms, IDs especially
T9_ = copy(T8_)
T9_1 = copy(T8_[, .SD, .SDcols = !c("date_update","away_team_api_id","home_team_api_id")])
T9_1 = merge(T9_1, League.table[,.SD,.SDcols = c("country_id","name")], by = "country_id", all.x = TRUE)
setnames(T9_1, "name","League.name")
T9_ = T9_[,-c(1:25), with = F]
View(T9_)
dim(T9_)
T9_[,Outcome := ifelse(home_team_goal > away_team_goal,"W", ifelse(home_team_goal < away_team_goal, "L","D"))]
View(T9_[,list(HomeTeam, home_team_goal, AwayTeam, away_team_goal, Outcome)])
T9_[,stage:= cut(T9_[,stage], breaks = seq(0,40, by = 10))]
View(T9_)
Final.Data = T9_[complete.cases(T9_),]
View(Final.Data)
summary(Final.Data)
dim(Final.Data)

#Add league name
Final.Data = merge(Final.Data, League.table[,.SD,.SDcols = c("country_id","name")], by = "country_id", all.x = TRUE)
setnames(Final.Data, "name","League.name")
View(Final.Data)
col.to.drop = c("country_id","id","league_id","season","date","match_api_id")
Final.Data = Final.Data[,.SD,.SDcols = !col.to.drop]
summary(Final.Data)
dim(Final.Data)
str(Final.Data)
######Data Visualization############
#Will be using the English Premier League to model data
leagues = levels(as.factor(Final.Data$League.name))
Final.Data[,date:= lapply(.SD, substr, 1, 4), .SDcols = 'date']
Final.Data[,date:= lapply(.SD, as.numeric), .SDcols = 'date']
str(Final.Data)
str.colnames.factor = colnames(Final.Data)[lapply(Final.Data, class)=='character']
Final.Data[,str.colnames := lapply(.SD, as.factor), .SDcols = str.colnames]

Final.Data[,(str.colnames) := lapply(.SD, as.character), .SDcols = str.colnames]

selectTeamPlot = function(DT = Final.Data, league = leagues, Home = "HomeTeam", outcome = "W", type = "England",
                            selectTeam = c("Arsenal","Liverpool","Chelsea","Manchester United","Manchester City")){
    DT = copy(DT)
    league.name = match.arg(type,league)
    DT.new = DT[Outcome == outcome & League.name == league.name,.SD, .SDcols = c("date",Home,"Outcome")]
    plt.data = as.data.table(table(DT.new))
    plt.data[, c('date') := lapply(.SD, as.numeric), .SDcols = c('date')]
    setnames(plt.data, c("date",Home,"N"),c("Year","Team","Total"))
    p = plot_ly(data = filter(plt.data,Team %in% selectTeam) ) %>%
        add_trace(x = ~Year, y = ~Total, type = 'scatter', mode = 'lines+markers',
                  color = ~Team, text = ~paste("Team:",Team,"<br>","Year:",Year,"<br>","Total:",Total),
                  hoverinfo = 'text', line = list(smoothing = "1.3", width = 5) )
    return(p)
    
}

selectLeaguePlot = function(DT = Final.Data, league = leagues, Home = "HomeTeam", type = "England",
                            selectTeam = c("Arsenal","Liverpool","Chelsea","Manchester United","Manchester City"),
                            selectAtt = c("buildUpPlayDribbling")){
    DT = copy(DT)
    league.name = match.arg(type,league)
    old.name = switch(Home,
                      HomeTeam = paste0("Home_",team.attr.names),
                      AwayTeam = paste0("Away_",team.attr.names))
    setnames(DT,old.name, team.attr.names)
    DT.new = DT[League.name == league.name,.SD, .SDcols = c("date",Home,selectAtt)]
    DT.melt = melt(DT.new,id.vars = c("date",Home), variable.name = "Attributes", value.name = "Total")
    setnames(DT.melt, c("date","HomeTeam"),c("Year","Team"))
    #return(print(names(DT.melt)))
    setorder(DT.melt, Team, Year)
    p = plot_ly(unique(DT.melt[Team %in% selectTeam,])) %>%
        add_trace(x = ~Year, y = ~Total, color = ~Team, type = 'scatter', mode = 'lines+markers',
                  text = ~paste("Team:",Team,"<br>","Year:",Year,"<br>","Total:",Total,"<br>","Attributes:",Attributes),
                  hoverinfo = "text", line = list(width = 5, smoothing = 1.3))
    return(p)
}
selectPlayerPlot = function(DT = T9_1, yr = 2008, league = leagues, type = "England",
                            selectTeam = c("Arsenal","Liverpool","Chelsea","Manchester United","Manchester City"), 
                            plotVal = T){
    DT = copy(DT)
    league.name = match.arg(type,league)
    DT[,c("date") := lapply(.SD, substr, 1, 4), .SDcols = c("date")]
    DT[,c("date") := lapply(.SD, as.numeric), .SDcols = c("date")]
    home.name = c()
    home.rating = c()
    away.name = c()
    away.rating = c()
    for(i in seq(to = 11)){
        home.name[i] = paste0("home_player_",i)
        home.rating[i] = paste0("Home.Player.Rating.",i)
    }
    for(i in seq(to = 11)){
        away.name[i] = paste0("away_player_",i)
        away.rating[i] = paste0("Away.Player.Rating.",i)
    }
    DT.Home1 = DT[,.SD,.SDcols = c("HomeTeam","League.name","date",home.name)]
    DT.Home1 = melt(DT.Home1, id.vars = c("HomeTeam","League.name","date"), variable.name = "Player.Num", value.name = "player_id")
    DT.Home2 = DT[,.SD,.SDcols = c("HomeTeam","League.name","date",home.rating)]
    DT.Home2 = melt(DT.Home2, id.vars = c("HomeTeam","League.name","date"), variable.name = "Player.Rate", value.name = "player_rate")
    DT.Home = cbind(DT.Home1,DT.Home2[,.SD,.SDcols = c("Player.Rate","player_rate")])
    DT.Home.merge = merge(DT.Home, Player.table[,.SD,.SDcols = c("player_api_id","player_name","height","weight")],
                          by.x ="player_id", by.y = "player_api_id", all.x = T)
    setnames(DT.Home.merge, c("HomeTeam"),c("Team"))
    DT.Away1 = DT[,.SD,.SDcols = c("AwayTeam","League.name","date",away.name)]
    DT.Away1 = melt(DT.Away1, id.vars = c("AwayTeam","League.name","date"), variable.name = "Player.Num", value.name = "player_id")
    DT.Away2 = DT[,.SD,.SDcols = c("AwayTeam","League.name","date",away.rating)]
    DT.Away2 = melt(DT.Away2, id.vars = c("AwayTeam","League.name","date"), variable.name = "Player.Rate", value.name = "player_rate")
    DT.Away = cbind(DT.Away1,DT.Away2[,.SD,.SDcols = c("Player.Rate","player_rate")])
    DT.Away.merge = merge(DT.Away, Player.table[,.SD,.SDcols = c("player_api_id","player_name","height","weight")],
                          by.x ="player_id", by.y = "player_api_id", all.x = T)
    setnames(DT.Away.merge, c("AwayTeam"),c("Team"))
    DT.Total = rbind(DT.Home.merge,DT.Away.merge)
    #return(DT.Total)
    p = plot_ly(data = DT.Total[League.name == league.name & Team %in% selectTeam & date == yr,]) %>%
        add_trace(x = ~Team, y = ~player_rate, z = ~player_rate, colors = "Greys",type = "heatmap",
                  text = ~paste0("Player: ",player_name,"<br>",
                                 "Rating: ",player_rate,"<br>",
                                 "Team name: ",Team), hoverinfo = "text", zsmooth = "best") %>%
        add_trace(x = ~Team, y = ~player_rate, color = ~Team, type = "box", boxpoints = "outliers",
                  hoverinfo = "skip",line = list(width = 10), marker = list(size = 20),
                  whiskerwidth = 1)
    if (plotVal == T){
        return(p)    
    }
    else{
        return(DT.Total)
    }
    
    
    
}


countWLD.Home = as.data.table(table(Final.Data[League.name == leagues[2],HomeTeam], 
                 Final.Data[League.name == leagues[2], Outcome]))
setnames(countWLD.Home, c("V1","V2","N"), c("Team","WLD","Total"))
countWLD.Home
plot_ly(data  = countWLD.Home) %>%
  add_trace(x = ~Team, y = ~Total, type = 'bar', color = ~WLD)

countWLD.Away = as.data.table(table(Final.Data[League.name == leagues[2],AwayTeam], 
                                    Final.Data[League.name == leagues[2], Outcome]))
setnames(countWLD.Away, c("V1","V2","N"), c("Team","WLD","Total"))
countWLD.Away2 = countWLD.Away[,lapply(.SD, function(x) max(x)/1.1 ), by = 'Team', .SDcols = c("Total")]
countWLD.Away
countWLD.Away2
plot_ly() %>%
    add_trace(data  = countWLD.Away, x = ~Team, y = ~Total, type = 'bar', color = ~WLD, 
              text = ~paste("Team:",Team,'<br>',"Outcome:",WLD,"<br>","Total",Total),
              marker = list(color = 'spectral'), hoverinfo = 'text') %>%
  add_trace(data  = countWLD.Away2, x = ~Team, y = ~Total, type = 'scatter', mode = 'text', text = ~Team,
            textfont = list(color = 'black', size = 18), textposition = 'middle left',
           hoverinfo = 'none', showlegend = F) %>%
  layout(xaxis = list(showticklabels = F), 
         yaxis = list(title = "Total Wins/Loss/Draw", titlefont = list(size = 20, family = "Times New Roman")),
         title = "WINS/LOSSES/DRAWS Playing Away in the Premier League", 
         titlefont = list(family = "Times New Roman", size = 25))
########################################
#Build Models
########################################
#Model to use first will be xgboost
#First need to convert strings to factors
str.colnames = colnames(Final.Data)[lapply(Final.Data, class)=='character']
Final.Data[,(str.colnames) := lapply(.SD, as.factor), .SDcols = str.colnames]
str(Final.Data)

Final.Data.Sub = Final.Data[,-c('country_id','id','league_id','season','date',
                                'match_api_id','home_team_goal','away_team_goal',
                                'HomeTeam','AwayTeam', 'League.name'), with = FALSE]
dim(Final.Data.Sub)
str(Final.Data.Sub)

#train = sample(c(1:Final.Data.Sub[,.N]), 0.8*Final.Data.Sub[,.N])
train = createDataPartition(Final.Data.Sub$Outcome, p = 0.9, list = FALSE, times = 1)
summary(Final.Data.Sub[train,Outcome])
dtrain = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = Final.Data.Sub[train,]), 
                     label = as.numeric(Final.Data.Sub$Outcome[train])-1)
dtest = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = Final.Data.Sub[-train]), 
                     label = as.numeric(Final.Data.Sub$Outcome[-train])-1)

#####Find best XGBOOST model#######
findbestXGBoost = function(dtrain, dtest, DT = Final.Data.Sub,
                           train){
    max.val = -1
    best.model = c()
    list.of.xgboost = list()
    table.of.xgboost = list()
    names.of.parameters = list()
    total.accuracy = 0
    grid = expand.grid(eta = seq(0.05,0.4,length.out = 5),gamma = seq(0,6, by = 2),
                       max.depth = seq(2,10, by = 5),
                       min.child.weight = seq(1,5,by = 1))
    for (i in c(1:nrow(grid))){
        names.of.parameters[[paste0("model",i)]] = paste(names(grid),grid[i,],sep = "=")
        params = list(eta = grid$eta[i], max_depth = grid$max.depth[i], gamma = grid$gamma[i],
                      min_child_weight = grid$min.child.weight[i],num_class = 3,
                      eval_metric = c("mlogloss"),subsample = 1,
                      colsample_bytree = 0.5)
        Final.Data.Sub.Xg.CV = xgb.cv(params = params, data = dtrain, nfold = 10, 
                                      nrounds = 1000, prediction = TRUE,
                                      verbose = F, early_stopping_rounds = 7)
        Final.Data.Sub.Train = xgb.train(params = params, data = dtrain, nfold = 10, nrounds = 
                                             Final.Data.Sub.Xg.CV$best_ntreelimit,
                                         verbose = F, early_stopping_rounds = 7, 
                                         watchlist = list(train = dtrain))
        pred = predict(Final.Data.Sub.Train,dtest)
        list.of.xgboost[[paste0("model",i)]] = Final.Data.Sub.Train
        table.of.xgboost[[paste0("model",i)]] = table("Predicted"=pred,
                                                      "True"=as.numeric(DT$Outcome[-train])-1)
        for(j in c(1:nrow(table.of.xgboost[[paste0("model",i)]]))){
            total.accuracy = total.accuracy + table.of.xgboost[[paste0("model",i)]][j,j]
        }
            # table.of.xgboost[[paste0("model",i)]][1,1] + 
            # table.of.xgboost[[paste0("model",i)]][2,2] + 
            # table.of.xgboost[[paste0("model",i)]][3,3]
        if(total.accuracy > max.val){
            max.val = total.accuracy
            best.model = i
        }
        message(paste0("Iteration ",i," of ",nrow(grid)))
        print(table.of.xgboost[[paste0("model",i)]])
    }
    return(list(model = list.of.xgboost,
                table = table.of.xgboost,
                name = names.of.parameters,
                best.model = best.model))
   
}
model1.xgboost = findbestXGBoost(dtrain = dtrain, dtest = dtest, train = train)

params = list(eta = 0.005, max_depth = 5, objective = "multi:softmax", num_class = 3, eval_metric = c("mlogloss"),
              subsample = 0.5, n_thread = 4, colsample_bytree = 0.5)
Final.Data.Sub.Xg.CV = xgb.cv(params = params, data = dtrain, nfold = 10, nrounds = 700, prediction = TRUE,
                              verbose = TRUE, early_stopping_rounds = 7)
Final.Data.Sub.Train = xgb.train(params = params, data = dtrain, nfold = 10, 
                                 nrounds = Final.Data.Sub.Xg.CV$best_ntreelimit,
                                 verbose = TRUE, early_stopping_rounds = 7, 
                                 watchlist = list(train = dtrain))

pred = predict(Final.Data.Sub.Train,dtest)
table("Predicted"=pred,"True"=as.numeric(Final.Data.Sub$Outcome[-train])-1)
#This model seems to predict wins very well so lets now try 
#####multinomial classification#######

model2 = multinom(Outcome ~ ., data = Final.Data.Sub[train,], nrounds = 500)
pred2 = predict(model2, Final.Data.Sub[-train,])
table("Predicted"=pred2,"True"=Final.Data.Sub$Outcome[-train])

######Use Neural Networks##########
#Lets try neural network
# model3 = nnet(x = Final.Data.Sub[train,.SD,.SDcols = !c("Outcome")], y = Final.Data.Sub[train,Outcome],
#               maxit = 200, size = 2)
model3 = nnet(Outcome ~ ., data = Final.Data.Sub, subset = train,
              maxit = 500, size = 5, decay = 5e-3, trace = F)
pred3 = predict(model3,Final.Data.Sub[-train,.SD,.SDcols = !c("Outcome")], type = 'class')
table("Predicted"=pred3,"True"=Final.Data.Sub$Outcome[-train])


dummy.dataset = as.data.table(dummy.data.frame(Final.Data.Sub))
setnames(dummy.dataset,names(dummy.dataset),gsub("[._]","",names(dummy.dataset)))
setnames(dummy.dataset,c("stage(0,10]","stage(10,20]","stage(20,30]","stage(30,40]"),
         c("stage1","stage2","stage3","stage4"))
setnames(dummy.dataset, names(dummy.dataset),gsub(" ","",names(dummy.dataset)))
f = as.formula(paste("OutcomeD+OutcomeL+OutcomeW",
                      paste(names(dummy.dataset[,.SD,.SDcols = !c("OutcomeD","OutcomeL","OutcomeW")]),
                             collapse = "+"), sep = " ~ "))
dummy.dataset[,(names(dummy.dataset)) := lapply(.SD,function(x){((x-min(x))/((max(x)-min(x))))}),
              .SDcols = c(names(dummy.dataset))]
model3.neural = neuralnet(formula = f, data = dummy.dataset[train,],hidden = c(10), linear.output = F,
                          err.fct = "ce", act.fct = "logistic")
findbestneural = function(){
    list.of.neurals = list()
    grid = expand.grid(one = c(8:12), two = c(8:12))
    for(i in c(1:nrow(grid))){
        model3.neural = neuralnet(formula = f, data = dummy.dataset[train,],hidden = c(grid$one[i],grid$two[i]),
                                  linear.output = F,
                                  err.fct = "ce", act.fct = "logistic")
        list.of.neurals[[paste0("model", i)]] = model3.neural
    }
    return(list(model = list.of.neurals))
}
model3.neural = findbestneural()
model3.compute = compute(model3.neural,data = 
                             dummy.dataset[-train,.SD,.SDcols = !c("OutcomeD","OutcomeL","OutcomeW")])$net.result
model3.pred = apply(model3.compute,1,function(x){
    max.val = which(max(x))
    if(max.val == 1){
        "D"
    }else if(max.val == 2){
        "L"
    }else{
        "W"
    }
})
table("Predicted"=model.pred3,"True"=Final.Data.Sub$Outcome[-train])


#####Grid of parameters for neural network######
#####Stacking Method #1#######
determineBestnnet = function(DT = Final.Data.Sub, validate.train = train){
    DT = copy(DT)
    DT.names = names(DT)[!names(DT) %in% c("Outcome")]
    formula = paste0("Outcome ~ ",paste0(DT.names,collapse = " + "))
    DT.Train = DT[validate.train,]
    DT.Test = DT[-validate.train,]
    fold = createFolds(DT.Train$Outcome,k = 5,list = F)
    # fold = sample(1:5,length(train),replace = T)
    DT.Train[,("fold") := fold]
    list.of.models = list()
    bestAcc = -1
    #by = originally 1
    
    grid.of.val = expand.grid(size = c(1:10), decay = exp(seq(-15,-5, by = 5)),
                              maxit = seq(from = 200, to = 1000, by = 100))
    #For testing
    # grid.of.val = expand.grid(size = c(1:2), decay = exp(seq(-15,-5, by = 10)),
    #                           maxit = seq(from = 200, to = 1000, by = 500))
    model.names = apply(grid.of.val,1,function(x){paste0("nnet",paste0(x,collapse = "*"))})
    # return(model.names[1:10])
    ##add columns for each model
    for(i in seq(to = length(model.names))){
        DT.Train[,(model.names[i]) := character()]
        DT.Test[,(model.names[i]) := character()]
    }
    grid.parameters = apply(grid.of.val, 1, as.list)
    # return(head(grid.parameters,2))
    # return(class(as.list(as.data.frame(DT.Train[,.SD,.SDcols = c(model.names)]))))
    myfunction = function(x,y){
        for(j in seq(to = 5)){
            model = nnet(Outcome ~ ., data = DT.Train[fold != j,.SD,.SDcols = c(DT.names,"Outcome")],
                         maxit = y$maxit, size = y$size, decay = y$decay, trace = F)
            # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
            #              maxit = y$maxit, size = y$size, decay = y$decay)
            pred = predict(model,DT.Train[fold == j,.SD,.SDcols = c(DT.names)], type = 'class')
            x[which(DT.Train[,fold]==j)] = pred
        }
        return(x)
    }
    myfunction.test = function(x,y){
        model = nnet(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c(DT.names,"Outcome")],
                     maxit = y$maxit, size = y$size, decay = y$decay, trace = F)
        # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
        #              maxit = y$maxit, size = y$size, decay = y$decay)
        pred = predict(model,DT.Test[,.SD,.SDcols = c(DT.names)], type = 'class')
        x = pred
    }
    message("Step 1 done")
    # return(sapply(DT.Train[fold != 1,.SD,.SDcols = c(DT.names)], class))
    train.value = mapply(myfunction, x = as.list(as.data.frame(DT.Train[,.SD,.SDcols = c(model.names)])), y = grid.parameters)
    test.value = mapply(myfunction.test, x = as.list(as.data.frame(DT.Test[,.SD,.SDcols = c(model.names)])), y = grid.parameters)
    # return(View(train.value))
    DT.Train[,c(model.names) := as.data.table(train.value)]
    DT.Test[,c(model.names) := as.data.table(test.value)]
    DT.Train2 = cbind(DT.Train[,.SD,.SDcols = c(DT.names,"Outcome")],as.data.table(train.value))
    DT.Test2 = cbind(DT.Test[,.SD,.SDcols = c(DT.names,"Outcome")],as.data.table(test.value))
    
    message("Step 2 done")
    chr.name = names(DT.Train2)[lapply(DT.Train2,class)=='character']
    DT.Train2[,c(chr.name) := lapply(.SD,as.factor), .SDcols = c(chr.name)]
    DT.Train2[,c(chr.name) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(chr.name)]
    
    DT.Test2[,c(chr.name) := lapply(.SD,as.factor), .SDcols = c(chr.name)]
    DT.Test2[,c(chr.name) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(chr.name)]
    
    chr.name.factor1 = names(DT.Train2[,.SD,.SDcols = c(chr.name)])[lapply(
        DT.Train2[,.SD,.SDcols = c(chr.name)],function(x){length(levels(x))})==3]
    # message("Train:")
    # message(paste(chr.name.factor1,collapse = " + "))
    chr.name.factor2 = names(DT.Test2[,.SD,.SDcols = c(chr.name)])[
        lapply(DT.Test2[,.SD,.SDcols = c(chr.name)],function(x){length(levels(x))})==3]
    # message("Test:")
    # message(paste(chr.name.factor2,collapse = " + "))
    chr.name.factor = chr.name.factor1[chr.name.factor1 %in% chr.name.factor2]
    DT.Train3 = DT.Train2[,.SD,.SDcols = c(DT.names,"Outcome",chr.name.factor)]
    message("Step 3 done")
    setnames(DT.Train3, chr.name.factor, gsub("[*-.]","A",chr.name.factor))
    DT.Test3 = DT.Test2[,.SD,.SDcols = c(DT.names,"Outcome",chr.name.factor)]
    setnames(DT.Test3, chr.name.factor, gsub("[*-.]","A",chr.name.factor))
    # View(DT.Train[,.SD,.SDcols = c(model.names)])
    
    # for(i in seq(to = nrow(grid.of.val))){
    #     model3 = nnet(Outcome ~ ., data = DT, subset = validate.train,
    #                   maxit = grid.of.val$maxit[i], size = grid.of.val$size[i], 
    #                   decay = grid.of.val$decay[i])
    #     pred3 = predict(model3,DT[-validate.train,.SD,.SDcols = !c("Outcome")], type = 'class')
    # }
    # 
    # for(i in seq(to = nrow(grid.of.val))){
    #     model3 = nnet(Outcome ~ ., data = DT, subset = validate.train,
    #                   maxit = grid.of.val$maxit[i], size = grid.of.val$size[i], 
    #                   decay = grid.of.val$decay[i])
    #     pred3 = predict(model3,DT[-validate.train,.SD,.SDcols = !c("Outcome")], type = 'class')
    #     tble = table("Predicted"=pred3,"True"=DT$Outcome[-validate.train])
    #     Acc = 0
    #     for (k in seq(to = nrow(tble))){
    #         Acc = Acc + tble[k,k]
    #     }
    #     if(Acc > bestAcc){
    #         bestAcc = Acc
    #         bestModel = model3
    #     }
    #     message(paste(i,"of",nrow(grid.of.val),"is complete."))
    #  list.of.models[[i]] = model3       
    # }
    return(list(Train = DT.Train, Test = DT.Test, train.val = DT.Train2, test.val = DT.Test2, 
                train.final = DT.Train3, test.final = DT.Test3))
    # return(list(bestmodel = bestModel, models = list.of.models))
}
model3.New = determineBestnnet()
#Try lda and qda
# chr.names = names(model3$train.val)[lapply(model3$train.val, class)=='character']
# Final.Data[,(str.colnames) := lapply(.SD, as.factor), .SDcols = str.colnames]
# str(Final.Data)
# chr.name3 = names(model3$train.val)[lapply(model3$train.val,function(x){length(levels(x))} ) > 1]
# model3$train.val[,(chr.names) := lapply(.SD, as.factor), .SDcols = chr.names]
# str(model3$train.val)
str(model3.New$train.final)
str(model3.New$test.final)
dtrain1 = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = model3.New$train.final), 
                     label = as.numeric(model3.New$train.final$Outcome)-1)
dtest1 = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = model3.New$test.final), 
                     label = as.numeric(model3.New$test.final$Outcome)-1)
params1 = list(eta = 0.005, max_depth = 5, objective = "multi:softmax", num_class = 3, eval_metric = c("mlogloss"),
              subsample = 0.85, n_thread = 4)
Final.Data.Sub.Xg.CV1 = xgb.cv(params = params1, data = dtrain1, nfold = 10, nrounds = 500, prediction = TRUE,
                              verbose = TRUE, early_stopping_rounds = 7)
Final.Data.Sub.Train1 = xgb.train(params = params1, data = dtrain1, nfold = 10, nrounds = Final.Data.Sub.Xg.CV1$best_ntreelimit,
                                 verbose = TRUE, early_stopping_rounds = 7, watchlist = list(train = dtrain1, test = dtest1))
# Final.Data.Sub.Train1 = xgb.train(params = params1, data = dtrain1, nfold = 10, nrounds = 500,
#                                   verbose = TRUE, early_stopping_rounds = 7, watchlist = list(train = dtrain1))

pred4 = predict(Final.Data.Sub.Train1,dtest1, type = 'class')
table("Predicted"=pred4,"True"=as.numeric(model3.New$test.final[,Outcome])-1)
#######Build Models without Individual Player ratings################
names.rating = grep("Rating",names(Final.Data.Sub), value = T)
Final.Data.Sub.no.rating = Final.Data.Sub[,.SD,.SDcols = !c(names.rating)]

model6 = multinom(Outcome ~ ., data = Final.Data.Sub.no.rating, subset = train, nrounds = 500,
                  trace = F)
pred6 = predict(model6, Final.Data.Sub.no.rating[-train,], type = 'class')
table("Predicted"=pred6,"True"=Final.Data.Sub.no.rating$Outcome[-train])

#Lets try xgboost
dtrain2 = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = Final.Data.Sub.no.rating[train,]), 
                      label = as.numeric(Final.Data.Sub.no.rating$Outcome[train])-1)
dtest2 = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = Final.Data.Sub.no.rating[-train,]), 
                     label = as.numeric(Final.Data.Sub.no.rating$Outcome[-train])-1)
params2 = list(eta = 0.01, max_depth = 5, objective = "multi:softmax", num_class = 3, eval_metric = c("mlogloss"),
               subsample = 0.95, n_thread = 4)
model.no.rating.xgboost = findbestXGBoost(dtrain = dtrain2, dtest = dtest2, train = train)
Final.Data.Sub.Xg.CV2 = xgb.cv(params = params2, data = dtrain2, nfold = 10, nrounds = 500, prediction = TRUE,
                               verbose = TRUE, early_stopping_rounds = 7)
Final.Data.Sub.Train2 = xgb.train(params = params2, data = dtrain2, nfold = 10, 
                                  nrounds = Final.Data.Sub.Xg.CV2$best_ntreelimit,
                                  verbose = TRUE, early_stopping_rounds = 7, 
                                  watchlist = list(train = dtrain2, test = dtest2))
# Final.Data.Sub.Train2 = xgb.train(params = params2, data = dtrain2, nfold = 10, nrounds = 500,
#                                   verbose = TRUE, early_stopping_rounds = 7, watchlist = list(train = dtrain2))
pred7 = predict(Final.Data.Sub.Train2,dtest2, type = 'class')
table("Predicted"=pred7,"True"=as.numeric(Final.Data.Sub.no.rating$Outcome[-train])-1)

#Lets try lda and dqa
model8 = lda(Outcome ~ ., data = Final.Data.Sub.no.rating, subset = train, method = 'mle')
pred8 = predict(model8,Final.Data.Sub.no.rating[-train,])$class
table("Predicted"=pred8,"True"=Final.Data.Sub.no.rating$Outcome[-train])

model9 = qda(Outcome ~ ., data = Final.Data.Sub.no.rating, subset = train, method = 'mle')
pred9 = predict(model9,Final.Data.Sub.no.rating[-train,])$class
table("Predicted"=pred9,"True"=Final.Data.Sub.no.rating$Outcome[-train])

####Stacking Method #2#########

#Lets try stacking
#This method will contain
#KNN, NNET, LDA, QDA, Multinomial Logistic Regression
#and use xgboost on the new meta features
stacking.method1 = function(DT = Final.Data.Sub.no.rating, validate.train = train){
  DT = copy(DT)
  DT.names = names(DT)[!names(DT) %in% c("Outcome")]
  formula = paste0("Outcome ~ ",paste0(DT.names,collapse = " + "))
  DT.Train = DT[validate.train,]
  DT.Test = DT[-validate.train,]
  fold = createFolds(DT.Train$Outcome,k = 5,list = F)
  # fold = sample(1:5,length(train),replace = T)
  DT.Train[,("fold") := fold]
  list.of.models = list()
  bestAcc = -1
  
  message("Begin KNN")
  # return(ceiling(sqrt(nrow(DT.Train))))
  knn.seq = seq(from = 1, to = ceiling(sqrt(nrow(DT.Train))), by = 2)
  # knn.seq = seq(from = 5, to = ceiling(sqrt(nrow(DT.Train))), by = 100)
  knn.model.names = c()
  DT.Train.dummy = as.data.table(dummy.data.frame(DT.Train[,.SD,.SDcols = !c("Outcome")]))
  DT.Test.dummy = as.data.table(dummy.data.frame(DT.Test[,.SD,.SDcols = !c("Outcome")]))
  DT.names.dummy = names(DT.Train.dummy)[!names(DT.Train.dummy) %in% c("Outcome","fold")]
  DT.Train.dummy[,c(DT.names.dummy) := lapply(.SD, function(x){(x-min(x))/(max(x)-min(x))}),
                 .SDcols = c(DT.names.dummy)]
  DT.Test.dummy[,c(DT.names.dummy) := lapply(.SD, function(x){(x-min(x))/(max(x)-min(x))}),
                 .SDcols = c(DT.names.dummy)]
  
  # return(summary(DT.Test.dummy))
  
  for(i in c(1:length(knn.seq))){
    knn.model.names[i] = paste0("knn.model.",i)
  }
  for(i in seq(to = length(knn.model.names))){
    DT.Train[,(knn.model.names[i]) := factor(levels = c("D","L","W"))]
    DT.Test[,(knn.model.names[i]) := factor(levels = c("D","L","W"))]
    # DT.Train[,(knn.model.names[i]) := character()]
    # DT.Test[,(knn.model.names[i]) := character()]
  }
  
  for(i in seq(to = length(knn.model.names))){
    for(j in c(1:5)){
      model.knn = knn3(DT.Train.dummy[fold != j,.SD,.SDcols = c(DT.names.dummy)],
                       DT.Train$Outcome[DT.Train$fold != j],
                       k = knn.seq[i])
      pred = predict(model.knn,DT.Train.dummy[fold == j,.SD,.SDcols = c(DT.names.dummy)],
                     type = 'class')
      DT.Train[fold == j,(knn.model.names[i]) := pred]
    }
  }
  for(i in seq(to = length(knn.model.names))){
    model.knn = knn3(DT.Train.dummy[,.SD,.SDcols = c(DT.names.dummy)],
                     DT.Train$Outcome,
                     k = knn.seq[i])
    pred = predict(model.knn,DT.Test.dummy[,.SD,.SDcols = c(DT.names.dummy)],
                   type = 'class')
    DT.Test[,(knn.model.names[i]) := pred]
  }
  # print(sapply(DT.Train,class))
  # print(sapply(DT.Train,levels))
  # print(sapply(DT.Test,class))
  # print(sapply(DT.Test,levels))
  # print(head(DT.Train))
  # return(head(DT.Test))
  message("Complete KNN")
  message("Begin Neural Network")
  ##neural network
  grid.of.val = expand.grid(size = seq(2,10,by = 2), decay = seq(-15,-5, by = 5),
                            maxit = seq(from = 200, to = 1000, by = 100))
  # grid.of.val = expand.grid(size = seq(2,10,by = 5), decay = exp(seq(-15,-5, by = 15)),
  # maxit = seq(from = 200, to = 1000, by = 1000))
  model.names = c()
  for(i in c(1:nrow(grid.of.val))){
    model.names[i] = paste0("model.",i)
  }
  for(i in seq(to = length(model.names))){
    DT.Train[,(model.names[i]) := character()]
    DT.Test[,(model.names[i]) := character()]
  }
  # DT.Train[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
  # DT.Test[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
  
  grid.parameters = apply(grid.of.val, 1, as.list)
  
  myfunction = function(x,y){
    for(j in seq(to = 5)){
      model = nnet(Outcome ~ ., data = DT.Train[fold != j,.SD,.SDcols = c(DT.names,"Outcome")],
                   maxit = y$maxit, size = y$size, decay = exp(y$decay), trace = F)
      # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
      #              maxit = y$maxit, size = y$size, decay = y$decay)
      pred = predict(model,DT.Train[fold == j,.SD,.SDcols = c(DT.names)], type = 'class')
      x[which(DT.Train[,fold]==j)] = pred
    }
    return(x)
  }
  myfunction.test = function(x,y){
    model = nnet(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c(DT.names,"Outcome")],
                 maxit = y$maxit, size = y$size, decay = exp(y$decay), trace = F)
    # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
    #              maxit = y$maxit, size = y$size, decay = y$decay)
    pred = predict(model,DT.Test[,.SD,.SDcols = c(DT.names)], type = 'class')
    x = pred
    return(x)
  }
  
  # return(sapply(DT.Train[fold != 1,.SD,.SDcols = c(DT.names)], class))
  
  train.value = mapply(myfunction, x = as.list(as.data.frame(DT.Train[,.SD,.SDcols = c(model.names)])),
                       y = grid.parameters)
  print(head(train.value))
  for(i in c(1:length(model.names))){
    DT.Train[,(model.names[i]) := factor(train.value[,i], levels = c("D","L","W"))]
    # levels(DT.Train[,(model.names[i])]) = c("D","L","W")
    # setattr(DT.Train[,(model.names[i])],"levels",c("D","L","W"))
    # DT.Train[,(model.names[i]) := lapply(.SD,setattr,"levels",c("L","W","D")), .SDcols = c(model.names[i])]
  }
  # levels(DT.Train[,(model.names)]) =  c("D","L","W")
  # print(sapply(DT.Train[,.SD,.SDcols = c(model.names)],levels))
  # print(sapply(DT.Train[,.SD,.SDcols = c(model.names)],class))
  # return(head(DT.Train))
  # print(sapply(DT.Train,class))
  # print(head(DT.Train))
  # DT.Train[,(model.names) := apply(mapply(myfunction,x = as.list(as.data.frame(.SD)), y = grid.parameters),2,as.list),
  #          .SDcols = c(model.names)]
  # DT.Train[,(model.names) := sapply(.SD,unlist),.SDcols = c(model.names)]
  test.value = mapply(myfunction.test, x = as.list(as.data.frame(DT.Test[,.SD,.SDcols = c(model.names)])), 
                      y = grid.parameters)
  for(i in c(1:length(model.names))){
    DT.Test[,(model.names[i]) := factor(test.value[,i], levels = c("D","L",'W'))]
    # setattr(DT.Test[,(model.names[i])],"levels",c("D","L","W"))
    # DT.Test[,(model.names[i]) := lapply(.SD,setattr,"levels",c("L","W","D")), .SDcols = c(model.names[i])]
  }
  print(sapply(DT.Test[,.SD,.SDcols = c(model.names)],levels))
  print(sapply(DT.Test[,.SD,.SDcols = c(model.names)],class))
  
  # return(View(train.value))
  
  # DT.Train[,c(model.names) := train.value]
  
  # DT.Train[,c(model.names) := lapply(.SD,as.factor), .SDcols = c(model.names)]
  
  # DT.Train[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
  
  message("Neural Network Complete")
  message("Begin Multinomial Logistic Regression")
  #Multi-logistic regression
  DT.Train[,multi.log := factor()]
  DT.Test[,multi.log := factor()]
  levels(DT.Train$multi.log) = c("D","L","W")
  levels(DT.Test$multi.log) = c("D","L","W")
  # return(sapply(DT.Train,class))
  for(i in c(1:5)){
    # return(DT.Train[,Outcome])
    multi.log = multinom(Outcome ~ ., data = DT.Train[fold!=i,.SD,.SDcols = c("Outcome",DT.names)], nrounds = 500,
                         trace = F)
    pred = predict(multi.log,DT.Train[fold == i,],type = 'class')
    DT.Train[fold == i,multi.log := pred]
  }
  multi.log.test = multinom(Outcome ~ ., data = DT.Train[,.SD,.SDcols = c("Outcome",DT.names)],
                            nrounds = 500, trace = F)
  pred.test = predict(multi.log.test,DT.Test[,.SD,.SDcols = c(DT.names)],type = 'class')
  DT.Test[,multi.log := pred.test]
  
  message("Multinomial Regression Complete")
  message("Begin LDA")
  #Linear Discriminant Analysis
  DT.Train[,lda := factor()]
  DT.Test[,lda := factor()]
  levels(DT.Train$lda) = c("D","L","W")
  levels(DT.Test$lda) = c("D","L","W")
  for(i in c(1:5)){
    lda.model = lda(Outcome ~ ., data = DT.Train[fold !=i,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
    pred = predict(lda.model,DT.Train[fold == i,.SD,.SDcols = c(DT.names)])$class
    DT.Train[fold == i,lda := pred]
  }
  lda.test = lda(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
  pred.test = predict(lda.test,DT.Test[,.SD,.SDcols = c(DT.names)])$class
  DT.Test[,lda := pred.test]
  message("LDA Complete")
  message("Begin QDA")
  #Quadratic Discriminant Analysis
  DT.Train[,qda := factor()]
  DT.Test[,qda := factor()]
  levels(DT.Train$qda) = c("D","L","W")
  levels(DT.Test$qda) = c("D","L","W")
  for(i in c(1:5)){
    qda.model = qda(Outcome ~ ., data = DT.Train[fold !=i,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
    pred = predict(qda.model,DT.Train[fold == i,.SD,.SDcols = c(DT.names)])$class
    DT.Train[fold == i,qda := pred]
  }
  qda.test = qda(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
  pred.test = predict(qda.test,DT.Test[,.SD,.SDcols = c(DT.names)])$class
  DT.Test[,qda := pred.test]
  message("QDA Complete")
  message("Completed Stacking, use meta features with XGBOOST")
  #Completed Stacking
  
  dtrain = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = DT.Train[,.SD,.SDcols = !c("fold")]), 
                       label = as.numeric(DT.Train$Outcome)-1)
  dtest = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = DT.Test), 
                      label = as.numeric(DT.Test$Outcome)-1)
  params = list(eta = 0.001, max_depth = 5, objective = "multi:softmax", num_class = 3, eval_metric = c("mlogloss"),
                subsample = 0.95, n_thread = 4)
  Final.Data.Sub.Xg.CV = xgb.cv(params = params, data = dtrain, nfold = 10, nrounds = 500, prediction = TRUE,
                                verbose = F, early_stopping_rounds = 7)
  Final.Data.Sub.Train = xgb.train(params = params, data = dtrain, nfold = 10, 
                                   nrounds = Final.Data.Sub.Xg.CV$best_ntreelimit,
                                   verbose = F, early_stopping_rounds = 7, 
                                   watchlist = list(train = dtrain))
  
  pred = predict(Final.Data.Sub.Train,dtest, type = 'class')
  final.table = table("Predicted"=pred,"True"=as.numeric(DT.Test$Outcome)-1)
  return(list(Table = final.table, nnet.models = grid.of.val))
}
stacking.method1()
model.10=stacking.method1()

#This method will contain
#KNN, xgboost, LDA, QDA, Multinomial Logistic Regression
#and use xgboost on the new meta features
stacking.method2 = function(DT = Final.Data.Sub.no.rating, validate.train = train){
    DT = copy(DT)
    DT.names = names(DT)[!names(DT) %in% c("Outcome")]
    formula = paste0("Outcome ~ ",paste0(DT.names,collapse = " + "))
    DT.Train = DT[validate.train,]
    DT.Test = DT[-validate.train,]
    fold = createFolds(DT.Train$Outcome,k = 5,list = F)
    # fold = sample(1:5,length(train),replace = T)
    DT.Train[,("fold") := fold]
    list.of.models = list()
    bestAcc = -1
    
    message("Begin KNN")
    # return(ceiling(sqrt(nrow(DT.Train))))
    knn.seq = seq(from = 1, to = ceiling(sqrt(nrow(DT.Train))), by = 2)
    # knn.seq = seq(from = 5, to = ceiling(sqrt(nrow(DT.Train))), by = 100)
    knn.model.names = c()
    DT.Train.dummy = as.data.table(dummy.data.frame(DT.Train[,.SD,.SDcols = !c("Outcome")]))
    DT.Test.dummy = as.data.table(dummy.data.frame(DT.Test[,.SD,.SDcols = !c("Outcome")]))
    DT.names.dummy = names(DT.Train.dummy)[!names(DT.Train.dummy) %in% c("Outcome","fold")]
    DT.Train.dummy[,c(DT.names.dummy) := lapply(.SD, function(x){(x-min(x))/(max(x)-min(x))}),
                   .SDcols = c(DT.names.dummy)]
    DT.Test.dummy[,c(DT.names.dummy) := lapply(.SD, function(x){(x-min(x))/(max(x)-min(x))}),
                  .SDcols = c(DT.names.dummy)]
    
    # return(summary(DT.Test.dummy))
    
    for(i in c(1:length(knn.seq))){
        knn.model.names[i] = paste0("knn.model.",i)
    }
    for(i in seq(to = length(knn.model.names))){
        DT.Train[,(knn.model.names[i]) := factor(levels = c("D","L","W"))]
        DT.Test[,(knn.model.names[i]) := factor(levels = c("D","L","W"))]
        # DT.Train[,(knn.model.names[i]) := character()]
        # DT.Test[,(knn.model.names[i]) := character()]
    }
    
    for(i in seq(to = length(knn.model.names))){
        for(j in c(1:5)){
            model.knn = knn3(DT.Train.dummy[fold != j,.SD,.SDcols = c(DT.names.dummy)],
                             DT.Train$Outcome[DT.Train$fold != j],
                             k = knn.seq[i])
            pred = predict(model.knn,DT.Train.dummy[fold == j,.SD,.SDcols = c(DT.names.dummy)],
                           type = 'class')
            DT.Train[fold == j,(knn.model.names[i]) := pred]
        }
    }
    for(i in seq(to = length(knn.model.names))){
        model.knn = knn3(DT.Train.dummy[,.SD,.SDcols = c(DT.names.dummy)],
                         DT.Train$Outcome,
                         k = knn.seq[i])
        pred = predict(model.knn,DT.Test.dummy[,.SD,.SDcols = c(DT.names.dummy)],
                       type = 'class')
        DT.Test[,(knn.model.names[i]) := pred]
    }
    # print(sapply(DT.Train,class))
    # print(sapply(DT.Train,levels))
    # print(sapply(DT.Test,class))
    # print(sapply(DT.Test,levels))
    # print(head(DT.Train))
    # return(head(DT.Test))
    message("Complete KNN")
    message("Begin XGBOOST")
    dtrain = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, 
                                             data = DT.Train[,.SD,.SDcols = c(DT.names,"Outcome")]), 
                         label = as.numeric(DT.Train$Outcome)-1)
    dtest = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, 
                                            data = DT.Test[,.SD,.SDcols = c(DT.names,"Outcome")]), 
                        label = as.numeric(DT.Test$Outcome)-1)
    ##XGBOOST
    grid.of.val = expand.grid(eta = seq(0.05,0.3,length.out = 5),gamma = seq(0,6, by = 2),
                       max.depth = seq(2,10, by = 5),
                       min.child.weight = seq(0,2.5,length.out = 5))
    # grid.of.val = expand.grid(size = seq(2,10,by = 5), decay = exp(seq(-15,-5, by = 15)),
    # maxit = seq(from = 200, to = 1000, by = 1000))
    model.names = c()
    for(i in c(1:nrow(grid.of.val))){
        model.names[i] = paste0("model.",i)
    }
    for(i in seq(to = length(model.names))){
        DT.Train[,(model.names[i]) := character()]
        DT.Test[,(model.names[i]) := character()]
    }
    # DT.Train[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
    # DT.Test[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
    
    grid.parameters = apply(grid.of.val, 1, as.list)
    
    myfunction = function(x,y){
        for(j in seq(to = 5)){
            params = list(eta = grid$eta, max_depth = grid$max.depth, gamma = grid$gamma,
                          min_child_weight = grid$min.child.weight,num_class = 3,
                          eval_metric = c("mlogloss"),subsample = 1,
                          colsample_bytree = 0.5)
            model.CV = xgb.cv(params = params, data = dtrain[DT.Train$fold != j,], nfold = 5, 
                                          nrounds = 1000, prediction = TRUE,
                                          verbose = F, early_stopping_rounds = 7)
            model = xgb.train(params = params, data = dtrain[DT.Train$fold != j,], nfold = 5, 
                              nrounds = model.CV$best_ntreelimit,
                                             verbose = F, early_stopping_rounds = 7, 
                                             watchlist = list(train = dtrain[DT.Train$fold != j,]))
            pred = predict(model,dtrain[DT.Train$fold == j,])
            # model = nnet(Outcome ~ ., data = DT.Train[fold != j,.SD,.SDcols = c(DT.names,"Outcome")],
            #              maxit = y$maxit, size = y$size, decay = exp(y$decay), trace = F)
            # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
            #              maxit = y$maxit, size = y$size, decay = y$decay)
            # pred = predict(model,DT.Train[fold == j,.SD,.SDcols = c(DT.names)], type = 'class')
            x[which(DT.Train[,fold]==j)] = pred
        }
        return(x)
    }
    myfunction.test = function(x,y){
        params = list(eta = grid$eta, max_depth = grid$max.depth, gamma = grid$gamma,
                      min_child_weight = grid$min.child.weight,num_class = 3,
                      eval_metric = c("mlogloss"),subsample = 1,
                      colsample_bytree = 0.5)
        model.CV = xgb.cv(params = params, data = dtrain, nfold = 5, 
                          nrounds = 1000, prediction = TRUE,
                          verbose = F, early_stopping_rounds = 7)
        model = xgb.train(params = params, data = dtrain, nfold = 5, nrounds = model.CV$best_ntreelimit,
                          verbose = F, early_stopping_rounds = 7, 
                          watchlist = list(train = dtrain))
        pred = predict(model,dtest)
        # model = nnet(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c(DT.names,"Outcome")],
        #              maxit = y$maxit, size = y$size, decay = exp(y$decay), trace = F)
        # model = nnet(x = DT.Train[fold != j,.SD,.SDcols = c(DT.names)], y = class.ind(DT.Train[fold != j, Outcome]),
        #              maxit = y$maxit, size = y$size, decay = y$decay)
        # pred = predict(model,DT.Test[,.SD,.SDcols = c(DT.names)], type = 'class')
        x = pred
        return(x)
    }
    
    # return(sapply(DT.Train[fold != 1,.SD,.SDcols = c(DT.names)], class))
    
    train.value = mapply(myfunction, x = as.list(as.data.frame(DT.Train[,.SD,.SDcols = c(model.names)])),
                         y = grid.parameters)
    print(head(train.value))
    for(i in c(1:length(model.names))){
        DT.Train[,(model.names[i]) := factor(train.value[,i], levels = c("D","L","W"))]
        # levels(DT.Train[,(model.names[i])]) = c("D","L","W")
        # setattr(DT.Train[,(model.names[i])],"levels",c("D","L","W"))
        # DT.Train[,(model.names[i]) := lapply(.SD,setattr,"levels",c("L","W","D")), .SDcols = c(model.names[i])]
    }
    # levels(DT.Train[,(model.names)]) =  c("D","L","W")
    # print(sapply(DT.Train[,.SD,.SDcols = c(model.names)],levels))
    # print(sapply(DT.Train[,.SD,.SDcols = c(model.names)],class))
    # return(head(DT.Train))
    # print(sapply(DT.Train,class))
    # print(head(DT.Train))
    # DT.Train[,(model.names) := apply(mapply(myfunction,x = as.list(as.data.frame(.SD)), y = grid.parameters),2,as.list),
    #          .SDcols = c(model.names)]
    # DT.Train[,(model.names) := sapply(.SD,unlist),.SDcols = c(model.names)]
    test.value = mapply(myfunction.test, x = as.list(as.data.frame(DT.Test[,.SD,.SDcols = c(model.names)])), 
                        y = grid.parameters)
    for(i in c(1:length(model.names))){
        DT.Test[,(model.names[i]) := factor(test.value[,i], levels = c("D","L",'W'))]
        # setattr(DT.Test[,(model.names[i])],"levels",c("D","L","W"))
        # DT.Test[,(model.names[i]) := lapply(.SD,setattr,"levels",c("L","W","D")), .SDcols = c(model.names[i])]
    }
    print(sapply(DT.Test[,.SD,.SDcols = c(model.names)],levels))
    print(sapply(DT.Test[,.SD,.SDcols = c(model.names)],class))
    
    # return(View(train.value))
    
    # DT.Train[,c(model.names) := train.value]
    
    # DT.Train[,c(model.names) := lapply(.SD,as.factor), .SDcols = c(model.names)]
    
    # DT.Train[,c(model.names) := lapply(.SD,setattr,"levels",c("D","L","W")), .SDcols = c(model.names)]
    
    message("XGBOOST Complete")
    message("Begin Multinomial Logistic Regression")
    #Multi-logistic regression
    DT.Train[,multi.log := factor()]
    DT.Test[,multi.log := factor()]
    levels(DT.Train$multi.log) = c("D","L","W")
    levels(DT.Test$multi.log) = c("D","L","W")
    # return(sapply(DT.Train,class))
    for(i in c(1:5)){
        # return(DT.Train[,Outcome])
        multi.log = multinom(Outcome ~ ., data = DT.Train[fold!=i,.SD,.SDcols = c("Outcome",DT.names)], nrounds = 500,
                             trace = F)
        pred = predict(multi.log,DT.Train[fold == i,],type = 'class')
        DT.Train[fold == i,multi.log := pred]
    }
    multi.log.test = multinom(Outcome ~ ., data = DT.Train[,.SD,.SDcols = c("Outcome",DT.names)],
                              nrounds = 500, trace = F)
    pred.test = predict(multi.log.test,DT.Test[,.SD,.SDcols = c(DT.names)],type = 'class')
    DT.Test[,multi.log := pred.test]
    
    message("Multinomial Regression Complete")
    message("Begin LDA")
    #Linear Discriminant Analysis
    DT.Train[,lda := factor()]
    DT.Test[,lda := factor()]
    levels(DT.Train$lda) = c("D","L","W")
    levels(DT.Test$lda) = c("D","L","W")
    for(i in c(1:5)){
        lda.model = lda(Outcome ~ ., data = DT.Train[fold !=i,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
        pred = predict(lda.model,DT.Train[fold == i,.SD,.SDcols = c(DT.names)])$class
        DT.Train[fold == i,lda := pred]
    }
    lda.test = lda(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
    pred.test = predict(lda.test,DT.Test[,.SD,.SDcols = c(DT.names)])$class
    DT.Test[,lda := pred.test]
    message("LDA Complete")
    message("Begin QDA")
    #Quadratic Discriminant Analysis
    DT.Train[,qda := factor()]
    DT.Test[,qda := factor()]
    levels(DT.Train$qda) = c("D","L","W")
    levels(DT.Test$qda) = c("D","L","W")
    for(i in c(1:5)){
        qda.model = qda(Outcome ~ ., data = DT.Train[fold !=i,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
        pred = predict(qda.model,DT.Train[fold == i,.SD,.SDcols = c(DT.names)])$class
        DT.Train[fold == i,qda := pred]
    }
    qda.test = qda(Outcome ~ ., data = DT.Test[,.SD,.SDcols = c("Outcome",DT.names)], method = 'mle')
    pred.test = predict(qda.test,DT.Test[,.SD,.SDcols = c(DT.names)])$class
    DT.Test[,qda := pred.test]
    message("QDA Complete")
    message("Completed Stacking, use meta features with XGBOOST")
    #Completed Stacking
    
    dtrain = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = DT.Train[,.SD,.SDcols = !c("fold")]), 
                         label = as.numeric(DT.Train$Outcome)-1)
    dtest = xgb.DMatrix(sparse.model.matrix(Outcome ~ . -1, data = DT.Test), 
                        label = as.numeric(DT.Test$Outcome)-1)
    params = list(eta = 0.001, max_depth = 5, objective = "multi:softmax", num_class = 3, eval_metric = c("mlogloss"),
                  subsample = 0.95, n_thread = 4)
    Final.Data.Sub.Xg.CV = xgb.cv(params = params, data = dtrain, nfold = 10, nrounds = 500, prediction = TRUE,
                                  verbose = F, early_stopping_rounds = 7)
    Final.Data.Sub.Train = xgb.train(params = params, data = dtrain, nfold = 10, 
                                     nrounds = Final.Data.Sub.Xg.CV$best_ntreelimit,
                                     verbose = F, early_stopping_rounds = 7, 
                                     watchlist = list(train = dtrain))
    
    pred = predict(Final.Data.Sub.Train,dtest, type = 'class')
    final.table = table("Predicted"=pred,"True"=as.numeric(DT.Test$Outcome)-1)
    return(list(Table = final.table, nnet.models = grid.of.val))
}

