#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(mapproj)
library(fiftystater)
library(dplyr)

american_intro = 'Do foreign workers steal jobs from American workers in your 
area or industry? The question gets down to whether foreign workers are paid higher 
or lower than the industry median in a specific area. Use the tool below to find out. 
You can start from one location or occupation.'

foreigner_intro = 'Which companies in your industry underpay foreign workers? 
How about in your area of interest? 
You might want to avoid these employers who consistently lower than industry median wages 
to foreigners in order to avoid being hurt by potential policy changes. 
Use the tool below to find out. 
You can start from one location or occupation.'

data <- read.csv('data/data_for_use.csv',header=T)
states <- read.csv('data/states.csv',header=T)
data <- merge(states, data, by.x='state',by.y='WORKSITE_STATE')

get_location <- function(loc_string) {
    locs = unlist(strsplit(loc_string,','))
    if (length(locs) == 1){
        return(subset(data, WORKSITE_POSTAL_CODE==locs))
    } else {
        output = data %>% filter(WORKSITE_POSTAL_CODE %in% locs)
        return(output)
    }
}
get_occupation <- function(occ) {
    subset(data, SOC_BROAD_NAME == occ)
}

get_summary <- function(dt) {
    dt %>% group_by(underpay) %>%
        summarise(count=n())
}
get_summary_median <- function(dt) {
    dt %>% group_by(under_median) %>%
        summarise(count=n())
}

get_location_employer <- function(dt) {
    output <- dt %>% filter(under_median == TRUE) %>%
        group_by(EMPLOYER_NAME) %>%
        summarise(count=n()) %>%
        arrange(desc(count))
    
    if (nrow(output)>20){
        return(head(output,20))
    } else{
        return(output)
    }
}
get_location_occupation <- function(dt) {
    dt %>% filter(under_median == TRUE) %>%
        group_by(SOC_BROAD_NAME) %>%
        summarise(count=n()) %>%
        arrange(desc(count))
}

get_occupation_location <- function(dt) {
    dt %>% filter(under_median == TRUE) %>% 
        group_by(id) %>%
        summarise(count=n())
}

get_occupation_location_city <- function(dt) {
    output <- dt %>% filter(under_median == TRUE) %>% 
        group_by(WORKSITE_CITY) %>%
        summarise(count=n()) %>%
        arrange(desc(count))
    head(output,20)
}



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    user <- reactive({input$user_select})
    output$intro <- renderText({
        ifelse(user()=='american', american_intro, foreigner_intro)
    })
    
    # ====
    # top level values for location tab
    # ====
    location <- eventReactive(input$`location-confirm`, {
        get_location(input$`location_input`)
    })
    location_summary <- reactive({
        sum_dt <- get_summary(location())
        underpay = subset(sum_dt,underpay==TRUE)
        total_count = sum(sum_dt$count)
        underpay_count = ifelse(nrow(underpay)==0, 0, underpay$count)
        underpay_pct = round(underpay_count/total_count*100,1)
        
        sum_median_dt <- get_summary_median(location())
        under_median = subset(sum_median_dt,under_median==TRUE)
        under_median_count = ifelse(nrow(under_median)==0, 0, under_median$count)
        under_median_pct = round(under_median_count/total_count*100,1)
        
        data.frame(total_count=total_count, 
                   underpay_count=underpay_count,
                   underpay_pct = underpay_pct,
                   under_median_count=under_median_count,
                   under_median_pct=under_median_pct)
                
    })
    location_string <- eventReactive(
        input$`location-confirm`,
        input$`location_input`
    )
    
    # reactive outputs for location tab
    
    output$`location-summary-text` <- renderText({
        loc <- location_summary()
        paste('In zip code area(s) of ', 
              location_string(), 
              ', there were ', 
              loc$total_count,
              ' H-1B sponsored jobs in 2016. ',
              loc$under_median_count,
              ' jobs (',
              loc$under_median_pct,
              '%) were paid lower than the median wage of the city area.',
              loc$underpay_count,
              ' case (',
              loc$underpay_pct,
              '%) was paid lower than the prevailing wage.'
        )
    })
    
    output$`location-summary-plot` <- renderPlot({
        loc <- location_summary()
        ggplot(loc)+
            geom_rect(aes(xmin=0,xmax=100,ymin=2,ymax=2.8))+
            geom_rect(aes(xmin=0,xmax=loc$under_median_pct,ymin=1,ymax=1.8))+
            geom_rect(aes(xmin=0,xmax=loc$underpay_pct,ymin=0,ymax=0.8))+
            geom_text(aes(x=105, y=2.4, label='Total cases'), hjust = 0)+
            geom_text(aes(x=loc$under_median_pct+5, y=1.4, label='Cases under median pay'), hjust = 0)+
            geom_text(aes(x=loc$underpay_pct+5, y=0.4, label='Cases underpay'), hjust = 0)+
            theme_minimal()+
            xlab('')+
            ylab('Percent')+
            xlim(c(0,140))
    })
    
    output$`location-employer-text` <- renderText({
        'Top companies that paid lower than city median for H-1B workers in 2016'
    })
    output$`location-employer-plot` <- renderPlot({
        dt <- get_location_employer(location())
        ggplot(dt)+
            geom_bar(aes(x=reorder(EMPLOYER_NAME, count), y=count), stat='identity')+
            xlab('')+
            ylab('Number of cases')+
            coord_flip()+
            theme_minimal()
    })
    output$`location-occupation-text` <- renderText({
        'Top occupations that pay lower than city median for H-1B workers in 2016'
    })
    
    output$`location-occupation-plot` <- renderPlot({
        dt <- get_location_occupation(location())
        ggplot(dt)+
            geom_bar(aes(x=reorder(SOC_BROAD_NAME, count), y=count), stat='identity')+
            xlab('')+
            ylab('Number of cases')+
            coord_flip()+
            theme_minimal()
    })
    
    # ======
    # top level values for occupation tab:
    # ======

    occupation <- reactive({get_occupation(input$`occupation-selector`)})
    occupation_summary <- reactive({
        sum_dt <- get_summary(occupation())
        underpay = subset(sum_dt,underpay==TRUE)
        total_count = sum(sum_dt$count)
        underpay_count = ifelse(nrow(underpay)==0, 0, underpay$count)
        underpay_pct = round(underpay_count/total_count*100,1)
        
        sum_median_dt <- get_summary_median(occupation())
        under_median = subset(sum_median_dt,under_median==TRUE)
        under_median_count = ifelse(nrow(under_median)==0, 0, under_median$count)
        under_median_pct = round(under_median_count/total_count*100,1)
        
        data.frame(total_count=total_count, 
                   underpay_count=underpay_count,
                   underpay_pct = underpay_pct,
                   under_median_count=under_median_count,
                   under_median_pct=under_median_pct)
        
    })
    occupation_string <- reactive({input$`occupation-selector`})
    
    # reactive outputs for occupation tab
    
    output$`occupation-summary-text` <- renderText({
        occ <- occupation_summary()
        paste('For ', 
              tolower(occupation_string()), 
              ', there were ', 
              occ$total_count,
              ' H-1B sponsored jobs in 2016. ',
              occ$under_median_count,
              ' jobs (',
              occ$under_median_pct,
              '%) were paid lower than the median wage of jobs of the same occupation in the same city area.',
              occ$underpay_count,
              ' case (',
              occ$underpay_pct,
              '%) was paid lower than the prevailing wage.'
        )
    })
    
    output$`occupation-summary-plot` <- renderPlot({
        occ <- occupation_summary()
        ggplot(occ)+
            geom_rect(aes(xmin=0,xmax=100,ymin=2,ymax=2.8))+
            geom_rect(aes(xmin=0,xmax=occ$under_median_pct,ymin=1,ymax=1.8))+
            geom_rect(aes(xmin=0,xmax=occ$underpay_pct,ymin=0,ymax=0.8))+
            geom_text(aes(x=105, y=2.4, label='Total cases'), hjust = 0)+
            geom_text(aes(x=occ$under_median_pct+5, y=1.4, label='Cases under median pay'), hjust = 0)+
            geom_text(aes(x=occ$underpay_pct+5, y=0.4, label='Cases underpay'), hjust = 0)+
            theme_minimal()+
            xlab('')+
            ylab('Percent')+
            xlim(c(0,140))
    })
    
    output$`occupation-map-text` <- renderText({
        paste('Number of H-1B jobs in ',
              tolower(occupation_string()),
              ' that were paid lower than median wage in the city area in 2016')
    })
    
    output$`occupation-map-plot` <- renderPlot({
        occ_states <- get_occupation_location(occupation())
        ggplot(occ_states, aes(map_id = id)) + 
            geom_map(aes(fill = count), map = fifty_states) + 
            expand_limits(x = fifty_states$long, y = fifty_states$lat) +
            coord_map() +
            scale_x_continuous(breaks = NULL) + 
            scale_y_continuous(breaks = NULL) +
            labs(x = "", y = "") +
            theme(panel.background = element_blank())
    })
    
    output$`occupation-location-plot` <- renderPlot({
        occ_cities <- get_occupation_location_city(occupation())
        ggplot(occ_cities)+
            geom_bar(aes(x=reorder(WORKSITE_CITY, count), y=count), 
                     stat='identity')+
            xlab('')+
            ylab('Number of cases')+
            ggtitle('Top 20 cities with most lower-than-median H-1B jobs')+
            coord_flip()+
            theme_minimal()
    })
    
    output$`occupation-employer-text` <- renderText({
        'Top companies that paid lower than city median for H-1B workers in 2016'
    })
    
    output$`occupation-employer-plot` <- renderPlot({
        dt <- get_location_employer(occupation())
        ggplot(dt)+
            geom_bar(aes(x=reorder(EMPLOYER_NAME, count), y=count), stat='identity')+
            xlab('')+
            ylab('Number of cases')+
            coord_flip()+
            theme_minimal()
    })

    
})
