# server

library(maps)
library(dplyr)
library(shiny)
library(DT)
library(ggplot2)
library(ggthemes)
library(data.table)
library(reshape2)
library(shinyjs)


source("helpers.R")


# common 
columns_to_use = c(rep(NA, 2), rep("NULL", 2),rep(NA, 58))

# female data
female_lexp = read.csv('../data/API_SP.DYN.LE00.FE.IN_DS2_en_csv_v2.csv', 
                       header = TRUE, skip = 4, stringsAsFactors = FALSE, colClasses = columns_to_use)
female_lexp[58:60] <- NULL                                    # get rid of empty last 3 columns
female_lexp = female_lexp[order(female_lexp$Country.Name),]   # alpha-order by country name
rownames(female_lexp) = female_lexp$Country.Code              # temporarily make country code row names
country_names = female_lexp[,1:2]                             # create DF of countryname/code
rownames(country_names) = country_names$Country.Code          # temporarily make country code row names
female_lexp[1:2] <- NULL                                      # drop character columns

  # find empty rows
empty_DF <- female_lexp[rowSums(is.na(female_lexp)) == ncol(female_lexp),]  
  # get rid of countries w/ no data
country_names = country_names[!(rownames(country_names) %in% rownames(empty_DF)),,drop=FALSE] 
  # drop empty data rows
female_lexp = female_lexp[rowSums(is.na(female_lexp)) != ncol(female_lexp),]


# male data
male_lexp = read.csv('../data/API_SP.DYN.LE00.MA.IN_DS2_en_csv_v2.csv', 
                     header = TRUE, skip = 4, stringsAsFactors = FALSE, colClasses = columns_to_use)
male_lexp[58:60] <- NULL # get rid of empty last 3 columns
male_lexp = male_lexp[order(male_lexp$Country.Name),]
rownames(male_lexp) = male_lexp$Country.Code
male_lexp[1:2] <- NULL
male_lexp = male_lexp[rowSums(is.na(male_lexp)) != ncol(male_lexp),]

# put female/male rownames back as column
setDT(female_lexp, keep.rownames = TRUE)[]
setnames(female_lexp, 1, "Country.Code")
setDT(male_lexp, keep.rownames = TRUE)[]
setnames(male_lexp, 1, "Country.Code")
rownames(country_names) <- NULL # causes numeric re-ordering

# Misc variables
female_selected = c(1)
male_selected = c(2)
both_selected = c(1,2)


shinyServer(function(input, output) {
  
  # Various needed variables
  gender_requested = "Female"
  box_current_selected_indices = seq(1, nrow(country_names))
  box_new_selected_indicies = seq(1, nrow(country_names))
#  box_countries_requested = country_names
  linear_current_selected_indices = NULL
  linear_new_selected_indicies = NULL
#  linear_countries_requested = NULL
  female_dataset = female_lexp
  male_dataset = male_lexp
  both_dataset = NULL
  
  all_rows = seq(1, nrow(country_names))
  is_configured = TRUE
  
  
  processRequestedData <- function() {
    
    if(gender_requested=='Female'){
      female_dataset <<- female_lexp[box_current_selected_indices,-'Country.Code']
    } else if(gender_requested=='Male'){
      male_dataset <<- male_lexp [box_current_selected_indices,-'Country.Code']
    } else if(gender_requested=='Both'){
      female_dataset <<- female_lexp[box_current_selected_indices,-'Country.Code']
      male_dataset <<- male_lexp[box_current_selected_indices,-'Country.Code']
      female_mod = (female_lexp[box_current_selected_indices,-'Country.Code']) %>% mutate(Gender = as.factor("Female"))
      male_mod = (male_lexp[box_current_selected_indices,-'Country.Code']) %>% mutate(Gender = as.factor("Male"))
      both_dataset <<- rbind(female_mod,male_mod)
      
    }else { # default female
      female_dataset <<- female_lexp %>% select(-Country.Code)
    }
    
    
  }
  
  
  
  filtered_main_plot <- reactive({
    
    
    female_dataset %>% select(-Country.Code)
  })
  
  filtered_countries_linear <- reactive({
    
  })
  
  filtered_countries_box <- reactive({
    # bcl %>%
    #   filter(Price >= input$priceInput[1],
    #          Price <= input$priceInput[2],
    #          Type == input$typeInput,
    #          Country == input$countryInput
    #   )
  })
  
  # output$x1 = DT::renderDataTable(
  #   iris, server = FALSE,
  #   selection = list(mode = 'multiple', selected = c(1, 3, 8, 12))
  # )
  
  output$box_table = DT::renderDataTable(country_names, server = FALSE,
                                         selection = list(target = 'row',
                                                          mode = 'multiple', 
                                                          selected = seq(1, nrow(country_names))
                                                          )
                                         ) # pre-select all countries
  
  output$linear_table = DT::renderDataTable(country_names, server = FALSE,
                                            selection = list(target = 'row',
                                                             mode = 'multiple'
                                                             )
                                            ) # pre-select none
  
  output$dataset_table = DT::renderDataTable((female_lexp %>% left_join(country_names, by = "Country.Code") %>% select(-Country.Code))[,c(56,1:55)], server = FALSE,
                                            selection = list(target = 'row',
                                                             mode = 'multiple'
                                            )
  ) # pre-select none
  
  
  proxy_box_table = dataTableProxy('box_table')
  proxy_linear_table = dataTableProxy('linear_table')
  
  # Bloxplot Config Table
  observeEvent(input$selectAll_box, {
    proxy_box_table %>% selectRows(all_rows)
  })
  
  observeEvent(input$clearAll_box, {
    proxy_box_table %>% selectRows(NULL)
  })
  
  # LinearPlot Config Table
  observeEvent(input$selectAll_linear, {
    proxy_linear_table %>% selectRows(all_rows)
  })
  
  observeEvent(input$clearAll_linear, {
    proxy_linear_table %>% selectRows(NULL)
  })
  
  observeEvent(input$update_button, {
    print("ObserveEvent:UpdateBtn: Enter")
    
    # Get all configuration data
    # What genders are requested? (Need at least one checked)
    if (is.null(input$gender_group)) {
      is_configured <<- FALSE
      alert("You must select at least one gender.")
      print("ObserveEvent:UpdateBtn:No gender selected: Exit")
      return()
    }
    
    gender_number = as.numeric(input$gender_group)
    
    # What countries for plots (dont need any for linear, but need something for plot)?
    if (is.null(input$box_table_rows_selected)) {
      is_configured <<- FALSE
      alert("You must select at least one country for the box plot.")
      print("ObserveEvent:UpdateBtn:No countries selected: Exit")
      return()
    }
    
    
    box_new_selected_indices <<- input$box_table_rows_selected
    
    if(identical(box_new_selected_indices, box_current_selected_indices)){
      print("current and new indexes are the same\n\n")
      # cat('These box rows were selected(current,new):\n\n')
      # cat(box_current_selected_indices, sep = ', ')
      # cat('\n\n')
      # cat(box_new_selected_indices, sep = ', ')
    }else{ # lets update our indexes
      print("current and new indexes are NOT the same\n\n")
      # cat('These box rows were selected(current,new):\n\n')
      # cat(box_current_selected_indices, sep = ', ')
      # cat('\n\n')
      # cat(box_new_selected_indices, sep = ', ')
      
      box_current_selected_indices <<- box_new_selected_indices
    }
    
    # Gender configuration
    
    if(identical(female_selected,gender_number)){
      gender_requested <<- "Female"
      print("Female requested")
    }else if(identical(male_selected,gender_number)){
      gender_requested <<- "Male"
      print("Male requested")
    }else if (identical(both_selected,gender_number)){
      gender_requested <<- "Both"
      print("Both requested")
    }else {
      gender_requested <<- "Female"
      print("Defualt Female requested")
    }

    # Any linear countries
    if (length(input$linear_table_rows_selected)) {
      linear_new_selected_indices <<- input$linear_table_rows_selected
      # if (is.null(linear_current_selected_indices)){
      #   linear_current_selected_indices = linear_new_selected_indices
      # }
      # I might track current better if I need a reset to last state
      linear_current_selected_indices <<- linear_new_selected_indices
      # cat('These linear rows were selected:\n\n')
      # cat(linear_current_selected_indices, sep = ', ')
      # cat('\n\n')
    }else { # reset variables to NULL
      linear_new_selected_indices <<- NULL
      linear_current_selected_indices <<- NULL
    }
    
    print("ObserveEvent:UpdateBtn:setting is_configured = TRUE")
    is_configured <<- TRUE
    print("ObserveEvent:UpdateBtn: Exit")
  })
  
  output$min_max_textview <- renderPrint({
    "Min/Max Values"
    #(apply (female_lexp, 2, function(x) c(max (x,na.rm = TRUE), min(x,na.rm = TRUE))))[,-c(1,2)] 
    })
  
  
  output$countries_textview <- renderPrint({ 
    s = input$box_table_rows_selected
    if (length(s)) {
      cat('These countries were selected:\n\n')
      names = country_names[input$box_table_rows_selected,1]
      cat(names, sep = ', ')
    } 
    })
  
  output$main_plot <- renderPlot({
    print("renderPlot: ENTER")
    
    # make method reactive to input button
    # (weird: reactive variable will only stay that way if de-referenced prior to any null return)
    if(input$update_button){}
    
    print("is_configured=")
    print(is_configured)
    if (identical(is_configured,FALSE) ){
      print("renderPlot:Not Configured: EXIT")
      return()
    }
      
    processRequestedData()
    
    
    
    num_of_box_countries = length(box_current_selected_indices)
    
    # Title like "Female Life Expectancy In 256 Countries"
    plot_title = sprintf("Life Expectancy In %d %s",
                         num_of_box_countries,(ifelse(num_of_box_countries>1, "Countries", "Country")))
    
    plt = NULL
        
    if(gender_requested=='Female'){
      plt = ggplot(stack(female_dataset), aes(x = ind, y = values)) + geom_boxplot() 
      plot_title = paste("Female",plot_title)
      print("Female datset requested")
    } else if(gender_requested=='Male'){
      plt = ggplot(stack(male_dataset), aes(x = ind, y = values)) + geom_boxplot()
      plot_title = paste("Male",plot_title)
      print("Male datset requested")
    } else if(gender_requested=='Both'){
      df.melt = melt(both_dataset)
      plt = ggplot(df.melt, aes(x=variable, y=value, color=Gender)) + geom_boxplot(position="dodge")
      plot_title = paste("Female and Male",plot_title)
      print("Both datsets requested")
    }else {
      plt = ggplot(stack(female_dataset), aes(x = ind, y = values)) + geom_boxplot()
      plot_title = paste("Female",plot_title)
      print("Default Female datset requested")
    }
    
    
    
    plt = plt + 
      theme_minimal() + ggtitle(plot_title) +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) + 
      scale_y_continuous(name="Age", breaks=seq(0,90,10)) +
      scale_x_discrete(label=year_label_formatter, name="Year")
    
    
    # ggplot(data, aes(x=factor(X), y=Y, colour = factor(dep_C1)))  +
    #   geom_boxplot(outlier.size=0, fill = "white", position="identity", alpha=.5)  +
    #   stat_summary(fun.y=median, geom="line", aes(group=factor(dep_C1)), size=2) 
    
    # (plot1 <- ggplot(df1, aes(v, p)) + 
    #     geom_point() +
    #     geom_step(data = df2)
    # )
    
    print("renderPlot: EXIT")
    return(plt)
  })
  
#female_lexp = read.csv('../data/API_SP.DYN.LE00.FE.IN_DS2_en_csv_v2.csv', header = FALSE, skip = 4,stringsAsFactors = FALSE)  
#   output$map = renderPlot( {
# 
# args = switch(input$var,
#               "Percent White" = list(counties$white, "darkgreen", "% White"),
#               "Percent Black" = list(counties$black, "black", "% Black"),
#               "Percent Hispanic" = list(counties$hispanic, "darkorange", "% Hispanic"),
#               "Percent Asian" = list(counties$asian, "darkviolet", "% Asian"))
# 
# args$min = input$range[1]
# args$max = input$range[2]
# 
# do.call(percent_map, args)
#   })

  observe({ print(input$selectAll_box) })
  observe({ print(input$clearAll_box) })
  
  
  
})