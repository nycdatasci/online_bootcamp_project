library('dplyr')
library('ggplot2')
library("reshape2", lib.loc="~/R/win-library/3.3")
library("maps")
pdf("Gender Parity Index Analysis Report.pdf",onefile=T, paper="USr" )
gpi=read.csv(file='C:/Users/Smitha/Desktop/RProject/GPI_DATA.csv',header=TRUE,sep=",",quote="\"", stringsAsFactors = FALSE, fill=FALSE, check.names = FALSE)
country=read.csv(file='C:/Users/Smitha/Desktop/RProject/COUNTRY_DATA.csv',header=TRUE,sep=",",quote="\"", fill=FALSE,stringsAsFactors = FALSE)
gpijoined=left_join(country,gpi,by="CountryCode")
gpijoined.df=melt(gpijoined)
gpijoined.df = rename(gpijoined.df, Year=variable, GPI=value)
gpijoined.df$Year=as.numeric(levels(gpijoined.df$Year))[gpijoined.df$Year]


gpiplot = select(gpijoined.df, c(CountryCode,CountryName,Region,IncomeGroup,Year,GPI))
#Low Income Group
lic=filter(gpiplot,gpiplot$CountryCode=="LIC")
g <- ggplot(data=lic, aes(x=Year, y=GPI))
g+geom_line(aes(color=CountryName)) 
mtext("Hello World")

lic=filter(gpiplot,gpiplot$CountryCode=="HIC")
g <- ggplot(data=lic, aes(x=Year, y=GPI))
g+geom_line(aes(color=CountryName)) 

# 2014
Y2014=filter(gpiplot,gpiplot$Year=="2014")
g <- ggplot(data=Y2014, aes(x=CountryCode, y=GPI))
g+geom_bar(aes(color=IncomeGroup)) 

# 2014
g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+ geom_density_2d(show.legend=FALSE)

g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+ geom_point(alpha=.1)


g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+ geom_boxplot(show.legend=FALSE)+ geom_jitter(width = 0.2)

# 2014
g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+ geom_bin2d()+ geom_density2d(show.legend=FALSE)


#Based on Income Group
cmp=filter(gpiplot,gpiplot$CountryCode %in% c("HIC","HPC", "LDC","LIC","LMC","LMY","MIC","UMC"))
g <- ggplot(data=cmp, aes(x=Year, y=GPI))
g+geom_line(aes(color=CountryName))  +labs(color="Income Levels")

#Based on Region
cmp=filter(gpiplot,gpiplot$CountryCode %in% c("ARB","CEB","EAP","EAS","ECS","EMU","FCS","LAC","MEA","MNA","SSF"))
g <- ggplot(data=cmp, aes(x=Year, y=GPI))
g+geom_line(aes(color=CountryName)) +labs(color="Region")

#map('world', fill = TRUE, col = 1:10)) )


#Color By Country
g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+geom_line(aes(color=CountryName))




#Color By Region
g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+geom_line(aes(color=Region))

#Color By Income
g <- ggplot(data=gpiplot, aes(x=Year, y=GPI))
g+geom_point(aes(color=IncomeGroup))


dev.off()

