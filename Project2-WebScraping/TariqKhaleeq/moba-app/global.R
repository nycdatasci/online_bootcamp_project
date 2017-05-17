# global.R for moba
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(googleVis)

loldata<-read.delim("LOL_moba_champs.txt",header = FALSE, stringsAsFactors = FALSE)
# add colum names
colnames(loldata)<-c("Champ","Alias","pos1","pickrate1","winrate1","pos2","pickrate2","winrate2","damage","toughness","cc","mobility","utility")

whoWins<- function(champ1,champ2){
  champ1data<-loldata %>% filter(Champ == champ1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ2data<-loldata %>% filter(Champ == champ2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  
  statChamp1<- (sum(champ1data[,4:8])*champ1data$damage^2) * (as.integer(strsplit(champ1data$winrate1,"[%]")[[1]]))/100
  statChamp2<- (sum(champ2data[,4:8])*champ2data$damage^2) * (as.integer(strsplit(champ2data$winrate1,"[%]")[[1]]))/100
  
  if (statChamp1 > statChamp2){
    return (paste("The winner is: ",champ1))
  }else if (statChamp1 == statChamp2){
    return (paste("Both champs are equal. The winner would depend on farming and champ build"))
  }else{
    return (paste("The winner is: ",champ2))
  }
  
}

champStats<-function(champ1,champ2){
  champ1data<-loldata %>% filter(Champ == champ1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ2data<-loldata %>% filter(Champ == champ2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  
  combo<-rbind(champ1data[,c(1,4:8)],champ2data[,c(1,4:8)])
  
  comboChart<-gvisColumnChart(combo,options=list(width="700",legend='bottom',colors="['#004949','#198989','#36A679','#E46B2A','#F48950']"))
  return (comboChart)
}

whowinsTeam<-function(champ1,champ2,champ3,champ4,champ5,ochamp1,ochamp2,ochamp3,ochamp4,ochamp5){
  champ1data<-loldata %>% filter(Champ == champ1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ2data<-loldata %>% filter(Champ == champ2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ3data<-loldata %>% filter(Champ == champ3) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ4data<-loldata %>% filter(Champ == champ4) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ5data<-loldata %>% filter(Champ == champ5) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp1data<-loldata %>% filter(Champ == ochamp1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp2data<-loldata %>% filter(Champ == ochamp2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp3data<-loldata %>% filter(Champ == ochamp3) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp4data<-loldata %>% filter(Champ == ochamp4) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp5data<-loldata %>% filter(Champ == ochamp5) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  
  statChamp1<- (sum(champ1data[,4:8])*champ1data$damage^2) * (as.integer(strsplit(champ1data$winrate1,"[%]")[[1]]))/100
  statChamp2<- (sum(champ2data[,4:8])*champ2data$damage^2) * (as.integer(strsplit(champ2data$winrate1,"[%]")[[1]]))/100
  statChamp3<- (sum(champ3data[,4:8])*champ3data$damage^2) * (as.integer(strsplit(champ3data$winrate1,"[%]")[[1]]))/100
  statChamp4<- (sum(champ4data[,4:8])*champ4data$damage^2) * (as.integer(strsplit(champ4data$winrate1,"[%]")[[1]]))/100
  statChamp5<- (sum(champ5data[,4:8])*champ5data$damage^2) * (as.integer(strsplit(champ5data$winrate1,"[%]")[[1]]))/100
  statoChamp1<- (sum(ochamp1data[,4:8])*ochamp1data$damage^2) * (as.integer(strsplit(ochamp1data$winrate1,"[%]")[[1]]))/100
  statoChamp2<- (sum(ochamp2data[,4:8])*ochamp2data$damage^2) * (as.integer(strsplit(ochamp2data$winrate1,"[%]")[[1]]))/100
  statoChamp3<- (sum(ochamp3data[,4:8])*ochamp3data$damage^2) * (as.integer(strsplit(ochamp3data$winrate1,"[%]")[[1]]))/100
  statoChamp4<- (sum(ochamp4data[,4:8])*ochamp4data$damage^2) * (as.integer(strsplit(ochamp4data$winrate1,"[%]")[[1]]))/100
  statoChamp5<- (sum(ochamp5data[,4:8])*ochamp5data$damage^2) * (as.integer(strsplit(ochamp5data$winrate1,"[%]")[[1]]))/100
  
  yourteamScore<-sum(statChamp1,statChamp2,statChamp3,statChamp4,statChamp4)
  oppteamScore<-sum(statoChamp1,statoChamp2,statoChamp3,statoChamp4,statoChamp4)
  if (yourteamScore > oppteamScore){
    ans<-"Red team wins!"
    return (ans)
  }else if (statChamp1 == statChamp2){
    ans<-"Both teams are equal. The winner would depend on farming and champ build"
    return (ans)
  }else{
    ans<-"Blue team wins!"
    return (ans)
  }
}

teamStats<-function(champ1,champ2,champ3,champ4,champ5,ochamp1,ochamp2,ochamp3,ochamp4,ochamp5){
  champ1data<-loldata %>% filter(Champ == champ1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ2data<-loldata %>% filter(Champ == champ2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ3data<-loldata %>% filter(Champ == champ3) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ4data<-loldata %>% filter(Champ == champ4) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  champ5data<-loldata %>% filter(Champ == champ5) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp1data<-loldata %>% filter(Champ == ochamp1) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp2data<-loldata %>% filter(Champ == ochamp2) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp3data<-loldata %>% filter(Champ == ochamp3) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp4data<-loldata %>% filter(Champ == ochamp4) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  ochamp5data<-loldata %>% filter(Champ == ochamp5) %>% select(Champ, pickrate1, winrate1, damage, toughness, cc, mobility, utility)
  
  comboTeamA<-rbind(champ1data[,c(1,4:8)],
                    champ2data[,c(1,4:8)],
                    champ3data[,c(1,4:8)],
                    champ4data[,c(1,4:8)],
                    champ5data[,c(1,4:8)])
  comboTeamB<-rbind(ochamp1data[,c(1,4:8)],
                    ochamp2data[,c(1,4:8)],
                    ochamp3data[,c(1,4:8)],
                    ochamp4data[,c(1,4:8)],ochamp5data[,c(1,4:8)])
  
  teamAScore<-colSums(comboTeamA[,2:6])
  teamBScore<-colSums(comboTeamB[,2:6])
  
  finalTeamScore<-cbind(data.frame(Team=c('Red Team','Blue Team')),rbind(teamAScore,teamBScore))
  
  teamGraphStats<-gvisColumnChart(finalTeamScore,options=list(legend='bottom',colors="['#004949','#198989','#36A679','#E46B2A','#F48950']"))
  return (teamGraphStats)
}

