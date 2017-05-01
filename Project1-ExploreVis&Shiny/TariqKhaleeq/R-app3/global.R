# Global.R
library(dplyr)
library(ggplot2)
library(googleVis)
library(shinydashboard)
library(DT)
library(leaflet)
## make table for grade A
rest.data<-read.csv("Restaurant_Health_Inspections.csv",stringsAsFactors = FALSE)
abc<-read.csv("Restaurant_Health_Inspections_plus.csv", stringsAsFactors = FALSE)



totalRest<-length(unique(rest.data[,1]))
types.of.cuisine<-length(unique(rest.data$CUISINE.DESCRIPTION))
types_of_violation<-length(unique(rest.data$VIOLATION.CODE))

gradeA<-rest.data %>% group_by(GRADE) %>% filter(GRADE=="A" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection" & CRITICAL.FLAG=="Not Critical")
noGradeA<-length(unique(gradeA$DBA))

gradeB<-rest.data %>% group_by(GRADE) %>% filter(GRADE=="B" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection" & CRITICAL.FLAG=="Not Critical")
noGradeB<-length(unique(gradeB$DBA))

gradeC<-rest.data %>% group_by(GRADE) %>% filter(GRADE=="C" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection" & CRITICAL.FLAG=="Not Critical")
noGradeC<-length(unique(gradeC$DBA))

closeRest<-rest.data %>% group_by(ACTION) %>% filter(ACTION=="Establishment Closed by DOHMH.  Violations were cited in the following area(s) and those requiring immediate action were addressed.")
totalCloseRest<-length(unique(closeRest))

crit<-crit<-rest.data %>% group_by(CRITICAL.FLAG) %>% filter(CRITICAL.FLAG=="Critical")
totalCrit<-length(unique(crit$DBA))

noviol<-rest.data %>% group_by(CRITICAL.FLAG) %>% filter(CRITICAL.FLAG=="Not Critical" & ACTION=="No violations were recorded at the time of this inspection.")
totalNoViol<-length(unique(noviol$DBA))

gradeATable<-rest.data%>%filter(GRADE=="A")%>%select(DBA,BORO,STREET, CUISINE.DESCRIPTION,VIOLATION.DESCRIPTION, SCORE, GRADE, GRADE.DATE,INSPECTION.TYPE)
gradeBTable<-rest.data%>%filter(GRADE=="B")%>%select(DBA,BORO,STREET, CUISINE.DESCRIPTION,VIOLATION.DESCRIPTION, SCORE, GRADE, GRADE.DATE,INSPECTION.TYPE)
gradeCTable<-rest.data%>%filter(GRADE=="C")%>%select(DBA,BORO,STREET, CUISINE.DESCRIPTION,VIOLATION.DESCRIPTION, SCORE, GRADE, GRADE.DATE,INSPECTION.TYPE)

# Critical, Non critical, not yet graded with A, B, C combo.

gradeACrit<-rest.data%>%group_by(GRADE)%>%filter(GRADE=="A" & CRITICAL.FLAG=="Critical")%>%
            select(DBA,BORO,STREET, CUISINE.DESCRIPTION,VIOLATION.DESCRIPTION, SCORE, GRADE, GRADE.DATE,INSPECTION.TYPE)

### GRADES
tally5<-rest.data %>% group_by(GRADE) %>% summarise(Total=n())
fig5<-ggplot(tally5[c(-1,-6,-7),],aes(x=factor(GRADE),y=Total,color=GRADE)) + 
  geom_bar(aes(fill=GRADE),stat="identity") + 
  geom_text(aes(label=Total),position=position_dodge(width=0.9), vjust=-0.25)+
  xlab("Types of Grades") +
  ggtitle("The total number and types of Grade") +
  theme(plot.title = element_text(hjust = 0.5),legend.position = "None")+
  labs(linetype="Type")

### FLAGS
tally4<-rest.data %>% group_by(CRITICAL.FLAG) %>% summarise(Total=n()) %>% arrange(desc(Total))

fig4<-ggplot(tally4,aes(x=factor(CRITICAL.FLAG),y=Total,color=CRITICAL.FLAG)) + 
  geom_bar(aes(fill=CRITICAL.FLAG),stat="identity") + 
  geom_text(aes(label=Total),position=position_dodge(width=0.9), vjust=-0.25)+
  xlab("Types of Flag") +
  ggtitle("Number and types of Flag") +
  theme(plot.title = element_text(hjust = 0.5),legend.position = "None")+
  labs(linetype="Type") +
  scale_x_discrete(limits=c('Critical','Not Critical','Not Applicable'))

### CUISINES
tally<-rest.data %>%group_by(CUISINE.DESCRIPTION) %>% summarise(Total=n()) %>% arrange(desc(Total))
tally$CUISINE.DESCRIPTION<-factor(tally$CUISINE.DESCRIPTION, levels=tally$CUISINE.DESCRIPTION)

fig1<-ggplot(tally[1:20,], aes(x=CUISINE.DESCRIPTION, y=Total)) + 
  geom_bar(aes(fill=CUISINE.DESCRIPTION), stat="identity") +
  labs(title="Top 20 Cuisines with highest violation",x="Cuisines", y = "Amount of violations per cuisine") + 
  theme(plot.title = element_text(hjust = 0.5),axis.text.x = element_blank()) +
  scale_fill_discrete(name="Types of cuisines in Manhattan")

### Types of violation
tally3<-rest.data %>%group_by(VIOLATION.DESCRIPTION) %>% summarise(Total=n()) %>% arrange(desc(Total))
tally3[c(1,7,8),1]<-c("Non-food contact surface improperly constructed.","Plumbing not properly installed or maintained","Filth flies or food/refuse/sewage-associated (FRSA) flies present in facility\032s food and/or non-food areas.")
tally3$VIOLATION.DESCRIPTION<-factor(tally3$VIOLATION.DESCRIPTION, levels=tally3$VIOLATION.DESCRIPTION)
tall3top10<-tally3[1:10,]

fig3<-ggplot(tall3top10, aes(x=VIOLATION.DESCRIPTION, y=Total)) + 
  geom_bar(aes(fill=VIOLATION.DESCRIPTION), stat="identity", width=0.2) +
  geom_text(aes(label=Total),position=position_dodge(width=0.9), vjust=-0.25) +
  labs(title="Top 10 reasons for violations",x="Reasons", y = "Total occurances of reasons") + 
  theme(plot.title = element_text(hjust = 0.5),axis.text.x = element_blank(),legend.justification=c(1,1),legend.position=c(1,1)) +
  scale_fill_discrete(name="Type of reasons")

tally6<-rest.data %>% filter(GRADE=="A") %>% summarise(TotalC=sum(CRITICAL.FLAG=="Critical"), TotalNC=sum(CRITICAL.FLAG=="Not Critical"))
tall6<-data.frame(CorNC=c("Total number of critical flags","Total number of non critical flags"), Total = c(as.integer(tally6)[1],as.integer(tally6)[2]))

Pie <- gvisPieChart(tall6,options=list(width="500",height="300",size="large",
                                       legend="bottom",
                                       title="Total number of critical flags vs non critical flags in Grade A restaurants"
))

#### Grade Pie charts (CRITICAL VS NON CRITICAL)
gradeACrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="A" & CRITICAL.FLAG=="Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gacTotal<-length(unique(gradeACrit$DBA))

gradeANoCrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="A" & CRITICAL.FLAG=="Not Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gancTotal<-length(unique(gradeANoCrit$DBA))

A<-data.frame(CorNC=c("Total number of critical flags","Total number of non critical flags"), Total = c((gacTotal-gancTotal),gancTotal))

PieA <- gvisPieChart(A,options=list(width="700",height="500", size="large",
                                   legend="bottom",
                                   title="Total number of critical flags vs non critical flags in Grade A restaurants",
                                   colors = "['#ec7063','#82e0aa']"
))

gradeBCrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="B" & CRITICAL.FLAG=="Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gacTotalB<-length(unique(gradeBCrit$DBA))

gradeBNoCrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="B" & CRITICAL.FLAG=="Not Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gancTotalB<-length(unique(gradeBNoCrit$DBA))

B<-data.frame(CorNC=c("Total number of critical flags","Total number of non critical flags"), Total = c((gacTotalB-gancTotalB),gancTotalB))

PieB <- gvisPieChart(B,options=list(width="700",height="500", size="large",
                                    legend="bottom",
                                    title="Total number of critical flags vs non critical flags in Grade B restaurants",
                                    colors = "['#ec7063','#82e0aa']"
))

gradeCCrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="C" & CRITICAL.FLAG=="Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gacTotalC<-length(unique(gradeCCrit$DBA))

gradeCNoCrit<-rest.data %>% group_by(DBA,GRADE,CRITICAL.FLAG) %>% filter(GRADE=="C" & CRITICAL.FLAG=="Not Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
gancTotalC<-length(unique(gradeCNoCrit$DBA))

C<-data.frame(CorNC=c("Total number of critical flags","Total number of non critical flags"), Total = c((gacTotalC-gancTotalC),gancTotalC))

PieC <- gvisPieChart(C,options=list(width="700",height="500", size="large",
                                    legend="bottom",
                                    title="Total number of critical flags vs non critical flags in Grade C restaurants",
                                    colors = "['#ec7063','#82e0aa']"
))

best<-rest.data %>% group_by(DBA, GRADE, CRITICAL.FLAG) %>% filter(GRADE=="A" | GRADE=="B" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection") %>% select(DBA,BORO, STREET, CUISINE.DESCRIPTION, GRADE, SCORE, CRITICAL.FLAG, VIOLATION.DESCRIPTION)
colnames(best)<-c("Restaurant","City","Street","Cuisine","Grade","Score","Critical Flag","Violaton")
bestRestTable<- gvisTable(best[1:50,],option=list(page='enable', pageSize=10))

### MAP

beta<-abc %>% group_by(DBA,GRADE,CRITICAL.FLAG,INSPECTION.TYPE)%>%filter(CRITICAL.FLAG=="Not Critical" & INSPECTION.TYPE=="Cycle Inspection / Re-inspection")
colnames(beta[,c(16,17)])<-c("lon","lat")



co<-readElement(beta)
