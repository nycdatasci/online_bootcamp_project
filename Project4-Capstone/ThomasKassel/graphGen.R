# Produce graphical outputs using data objects produced in EDA_featureEng.R and h2oModeling.R

library(data.table)
library(car)
library(psych)
library(graphics)
library(h2o)
library(ggplot2)
library(grid)
library(GGally)
library(scales)
library(reshape2)
library(Hmisc)
source("formatRECScodes.R")
source("helperFunctions.R")
source('EDA_featureEng.R')

#custom ggplot theme for consistency of graphics
light_theme <- function(base_size=12,text_color='gray15'){
  theme(
    plot.title = element_text(size=rel(1.2),vjust=2,hjust=0.5,colour=text_color),
    plot.margin = unit(c(1.2,1.2,1.2,1.2),"lines"),
    axis.ticks = element_line(size=0.15),
    axis.text = element_text(colour=text_color,size=rel(0.9)),
    axis.title.x = element_text(vjust=-0.8,size=base_size,colour=text_color,face = 'bold'),
    axis.title.y = element_text(vjust=1.3,size=base_size,colour=text_color,face = 'bold'),
    legend.title = element_text(face='bold'),
    panel.grid.major = element_line(size=0.15,colour='grey85'),
    panel.grid.minor = element_line(size=0.05,colour='grey85'),
    panel.background = element_rect(fill='white'),
    panel.border = element_rect(colour = "grey60", fill=NA, size=0.2),
    strip.background = element_rect(fill='grey80',colour="grey60",size=0.3),
    strip.text = element_text(colour=text_color,size=base_size)
  )
}

# Build factorComparisonGraph
walltype <- left_join(data.frame('codes' = recs$WALLTYPE),
                      filter(FinalCodebook,varName == 'WALLTYPE'),
                      by = 'codes') %>% select(varName,labels)
agefri1 <- left_join(data.frame('codes' = recs$AGERFRI1),
                     filter(FinalCodebook,varName == 'AGERFRI1'),
                     by = 'codes') %>% select(varName,labels)
graphdata <- rbind(walltype,agefri1) %>% dplyr::group_by(varName,labels) %>% dplyr::summarise('obs' = n())
graphdata$varName <- factor(graphdata$varName,levels = c('WALLTYPE','AGERFRI1'),ordered = T)
graphdata <- graphdata[complete.cases(graphdata),]

factorComparisonGraph <- ggplot(graphdata) + geom_bar(aes(x = labels, y = obs),stat = 'identity',fill = 'dodgerblue4',alpha = 0.8) + 
  xlab('Factor Levels') + ylab('# Observations') + ggtitle('Nominal vs Ordinal Factors\n') +
  facet_grid(.~varName,scales = 'free_x') + light_theme() + theme(axis.text.x = element_text(angle = 45,hjust=1))
ggsave(plot = factorComparisonGraph,filename = 'factorCompareBarchart.png',width = 7,height = 5)

# Build missingness plots
missingMatInt <- missingMat %>% select_if(is.integer) %>% cbind('KWH' = missingMat$KWH)
ggpairMissingIntGraph <- ggpairs(missingMatInt,axisLabels = 'show',upper = list(continuous = 'cor',na = 'blank'),diag = list(continuous = wrap('densityDiag',colour = 'dodgerblue4')),
                                 lower = list(continuous = wrap('points',alpha = 0.5,colour = 'dodgerblue4'),na = 'blank')) + 
  theme(axis.line=element_blank(),axis.text=element_blank(),axis.ticks=element_blank(),panel.grid.major= element_blank())
ggsave(plot = ggpairMissingIntGraph,filename = 'ggpairMissingIntGraph.png',width = 7,height = 5)

# Build numerics multicollinearity plot
numMulticollGraph <- ggcorr(recs.reduced.numeric, hjust = 0.95,size = 2.5, color = "grey20",layout.exp = 3,name = 'Correlation (r)')
ggsave(plot = numMulticollGraph,filename = 'numericMulticollHeatmap.png',width = 7,height = 5)


# Build GLMdefault coeff chart
roundCoefs <- function(name,coef){
  ifelse(name%in%c('TOTCSQFT','CDD30YR','HDD30YR'),round(coef,2),round(coef,0))
}
GLMpvalsGraph$coefficients <- mapply(roundCoefs,GLMpvalsGraph$names,GLMpvalsGraph$coefficients)
GLMtopPvalGraph <- ggplot(GLMpvalsGraph,aes(x = reorder(names,GLMpvalsGraph$z_value),y = z_value)) + geom_bar(stat = 'identity',fill = 'dodgerblue4',alpha = 0.8,width = 0.8) +
  light_theme() + coord_flip() + xlab('Feature') + ylab('Z-statistic') + 
  geom_text(aes(label = coefficients),hjust = 1.2,size = 5, colour = "white")
ggsave(plot = GLMtopPvalGraph,filename = 'GLM.PvaluesBarchart.png',width = 7,height = 5)


# Build final comparison prediction chart
predictionGraphData <- rbind(GBMgraphdata,GLMgraphdata) %>% melt(id = c('model','TOTCSQFT','CDD30YR','NHSLDMEM'))

predictionGraph <- ggplot(predictionGraphData) + geom_point(aes(x = CDD30YR,y = value,colour = variable),alpha =0.3) + 
  facet_grid(.~model) + light_theme() + scale_y_continuous(name = 'Annual kWh\n',labels=comma) + scale_x_continuous(name = '\nCDD30YR',labels=comma) +
  ggtitle('Predictive Performance on 10% Holdout Test Set\n') + theme(legend.position = 'top') +
  scale_colour_manual(name = '',breaks = c('actual','pred'),labels = c('Actual kWh','Predicted kWh'),values = c('dodgerblue4','yellowgreen'))
ggsave(plot = predictionGraph,filename = 'finalPredictionScatterplot.png',width = 7,height = 5)