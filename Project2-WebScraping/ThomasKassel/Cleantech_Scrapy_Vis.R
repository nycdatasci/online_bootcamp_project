# Analysis and visualization of data scraped from 'cleantechScrapy' python scripts
# Thomas Kassel 3-2-17

library(dplyr)
library(ggplot2)
library(grid)
library(gridExtra)
library(ggrepel)
library(scales)
source('../ggplot_theme.R')


##### Article Theme/Tag Analysis #####
ThemeTagData <- read.csv('ThemeTagOutput.csv',colClasses = c('character','factor','numeric'))

# Top themes and tags by total number of articles
ThemeTagData$type <- factor(ThemeTagData$type,levels = c('Theme','Tag'),ordered = T)
ThemeTagCounts <- group_by(ThemeTagData,topic,type) %>% summarise(numArticles=n()) %>% ungroup() %>%
                filter(!(topic%in%c('editors news feed','gtm research'))) %>% group_by(type) %>%
                top_n(n = 6,wt = numArticles) %>% filter(!(topic%in%c('trump','wind','energy efficiency')))

gg.ArticleCounts <- ggplot(data=ThemeTagCounts,aes(x=reorder(topic,-numArticles),y=numArticles,fill=type)) + 
    geom_bar(stat='identity',alpha=0.6,width = 0.7) + facet_grid(.~type,scales='free_x') + light_theme() + 
    scale_fill_brewer(palette='Set1') + theme(axis.text.x = element_text(angle = 30,vjust = 1,hjust=1),legend.position = 'none') +
    ylab('# of Articles\n') + xlab('\nTopic') + ggtitle('Most Frequent Article Topics')

# Distribution of comments by theme/tags
ThemeTagComments <- filter(ThemeTagData,topic%in%ThemeTagCounts$topic)

gg.ArticleCommentTheme <- ggplot(data=filter(ThemeTagComments,type=='Theme'),aes(x=numComments,fill=topic)) + 
    geom_histogram(alpha=0.7,binwidth=15,color='gray',size=0.4) + light_theme() +
    ylab('') + xlab('') + scale_fill_brewer(name='Theme',palette = 'RdYlBu')

gg.ArticleCommentTag <- ggplot(data=filter(ThemeTagComments,type=='Tag'),aes(x=numComments,fill=topic)) + 
    geom_histogram(alpha=0.7,binwidth=15,color='gray',size=0.4) + light_theme() +
    ylab('') + xlab('') + scale_fill_brewer(name='Tag',palette = 'RdYlBu')

gg.ArticleComments <- grid.arrange(gg.ArticleCommentTheme,gg.ArticleCommentTag,nrow=2,
                                   left = '# of Articles',bottom = '# of Comments',
                                   top = 'Number of Reader Comments by Article Topic')



##### Proper Noun Frequencies & NLP #####
bigcompanies <- read.csv('BigCompanies.csv',stringsAsFactors = F)
bigcompanies$type <- 'bigcompanies'
startups <- read.csv('Cleantech100.csv',stringsAsFactors = F)
startups$type <- 'startups'
people <- read.csv('BigPeople.csv',stringsAsFactors = F)
people$type <- 'people'
countries <- read.csv('Countries.csv',stringsAsFactors = F)
countries$type <- 'countries'

nouns <- rbind(bigcompanies,startups,people,countries)
nouns <- mutate(nouns,avgPolarity=sumPolarity/totalMentions,avgSubjectivity=sumSubjectivity/totalMentions)

gg.bigcompanies <- ggplot(data=filter(nouns,type=="bigcompanies"),aes(x=avgSubjectivity,y=avgPolarity,colour=totalMentions)) +
    geom_point(size=5) + scale_colour_gradient(name='Times\nMentioned',low='skyblue2',high='dodgerblue4') + 
    light_theme() + geom_hline(yintercept = 0,colour="red",size=.25,alpha=.5) + geom_label_repel(colour='gray30',aes(label=noun)) +
    theme(legend.position = 'right',legend.key.size = unit(1,'lines'),legend.background = element_rect(fill='gray90')) +
    scale_x_continuous(name='Subjectivity') + ylab('Polarity') + ggtitle('Large Companies')
