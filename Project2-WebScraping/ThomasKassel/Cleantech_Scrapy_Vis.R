# Analysis and visualization of data scraped from 'cleantechScrapy' python scripts
# Thomas Kassel 3-2-17

library(dplyr)
library(ggplot2)
library(grid)
library(gridExtra)
library(ggrepel)
library(scales)
source('../ggplot_theme.R')


######### Article Theme/Tag Analysis #########
ThemeTagData <- read.csv('ThemeTagOutput.csv',colClasses = c('character','factor','numeric'))

# Top themes and tags by total number of articles
ThemeTagData$type <- factor(ThemeTagData$type,levels = c('Theme','Tag'),ordered = T)
ThemeTagCounts <- group_by(ThemeTagData,topic,type) %>% summarise(numArticles=n()) %>% ungroup() %>%
                filter(!(topic%in%c('editors news feed','gtm research'))) %>% group_by(type) %>%
                top_n(n = 6,wt = numArticles) %>% filter(!(topic%in%c('trump','wind','energy efficiency')))

# Plot and save
gg.ArticleCounts <- ggplot(data=ThemeTagCounts,aes(x=reorder(topic,-numArticles),y=numArticles,fill=type)) + 
    geom_bar(stat='identity',alpha=0.6,width = 0.7) + facet_grid(.~type,scales='free_x') + light_theme() + 
    scale_fill_brewer(palette='Set1') + theme(axis.text.x = element_text(angle = 30,vjust = 1,hjust=1),legend.position = 'none') +
    ylab('# of Articles\n') + xlab('\nTopic') + ggtitle('Most Frequent Article Topics\n')
ggsave(plot = gg.ArticleCounts,filename = 'ArticleCounts.png',width=8,height=5)

# Distribution of comments by theme/tags
ThemeTagComments <- filter(ThemeTagData,topic%in%ThemeTagCounts$topic)
# Plot individually by theme and tag
gg.ArticleCommentTheme <- ggplot(data=filter(ThemeTagComments,type=='Theme'),aes(x=numComments,fill=topic)) + 
    geom_histogram(alpha=0.7,binwidth=15,color='gray',size=0.4) + light_theme() +
    ylab('') + xlab('') + scale_fill_brewer(name='Theme',palette = 'RdYlBu')

gg.ArticleCommentTag <- ggplot(data=filter(ThemeTagComments,type=='Tag'),aes(x=numComments,fill=topic)) + 
    geom_histogram(alpha=0.7,binwidth=15,color='gray',size=0.4) + light_theme() +
    ylab('') + xlab('') + scale_fill_brewer(name='Tag',palette = 'RdYlBu')

# Grid arrange and save
gg.ArticleComments <- grid.arrange(gg.ArticleCommentTheme,gg.ArticleCommentTag,nrow=2,
                                   left = '# of Articles',bottom = '# of Comments',
                                   top = 'Distribution of Reader Comments by Article Topic')
ggsave(plot = gg.ArticleComments,filename = 'ArticleComments.png',width=10,height=7)



######### Proper Noun Frequencies & NLP ######### 
# Read data and add type column
bigcompanies <- read.csv('BigCompanies.csv',stringsAsFactors = F)
bigcompanies$type <- 'bigcompanies'
startups <- read.csv('Cleantech100.csv',stringsAsFactors = F)
startups$type <- 'startups'
people <- read.csv('BigPeople.csv',stringsAsFactors = F)
people$type <- 'people'
countries <- read.csv('Countries.csv',stringsAsFactors = F)
countries$type <- 'countries'

# Calculate average polarity and subjectivity
nouns <- rbind(bigcompanies,startups,people,countries)
nouns <- mutate(nouns,avgPolarity=sumPolarity/totalMentions,avgSubjectivity=sumSubjectivity/totalMentions)
nouns$avgPolarity <- round(nouns$avgPolarity,2)
nouns$avgSubjectivity <- round(nouns$avgSubjectivity,2)

# Helper function for graphing
plotNoun <- function(nountype,title,nudge.x=.02,nudge.y=.02){
  # Given a noun type (people, countries, etc) plot and label polarity v. subjectivity
  data <- filter(nouns,type==nountype)
  gg <- ggplot(data=data,aes(x=avgSubjectivity,y=avgPolarity,colour=totalMentions)) +
      geom_point(size=5,alpha=0.9) + scale_colour_gradient(name='Times\nMentioned',low='forestgreen',high='dodgerblue4') + 
      light_theme() + geom_hline(yintercept = 0,colour="red",size=.25,alpha=.5) + 
      geom_label_repel(colour='gray30',aes(label=noun),nudge_y = nudge.y,nudge_x = nudge.x,box.padding = unit(.15,'lines'),size=3,
                       segment.colour = 'gray50',segment.alpha = .4) + theme(plot.title = element_text(size=16)) +
      theme(legend.position = 'right',legend.key.size = unit(1,'lines'),legend.background = element_rect(fill='gray90')) +
      scale_x_continuous(name='Subjectivity') + ylab('Polarity') + ggtitle(title)
  return(gg)
}

# Create and save plots
gg.bigcompanies <- plotNoun('bigcompanies',title='Large Companies',nudge.x = .008,nudge.y = .008)
gg.people <- plotNoun('people',title='Influential People',nudge.x = .008,nudge.y = -.008)
gg.startups <- plotNoun('startups',title='Startups',nudge.x = .018,nudge.y = -.018)
gg.countries <- plotNoun('countries',title='Countries',nudge.x = .008,nudge.y = .008)

ggsave(plot = gg.bigcompanies,filename = 'companies.png',width=6,height=5)
ggsave(plot = gg.people,filename = 'people.png',width=6,height=5)
ggsave(plot = gg.startups,filename = 'startups.png',width=8,height=7)
ggsave(plot = gg.countries,filename = 'countries.png',width=6,height=5)