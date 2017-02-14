## Helper file

job_filter <- function(df,value_list) {
  if(length(value_list) == 0) {
    return(df %>%
             mutate(JOB_INPUT_CLASS = JOB_TITLE))
  }
  
  new_df <- data.frame()
  
  for(value in value_list){
    new_df <- rbind(new_df, df %>% 
                      filter(regexpr(value,tolower(JOB_TITLE)) != -1) %>%
                      mutate(JOB_INPUT_CLASS = value))
  }
  return(new_df)
}

employer_filter <- function(df, value_list) {
  if(length(value_list) == 0) {
    return(df)
  }
  
  new_df <- data.frame()
  
  for(value in value_list){
    new_df <- rbind(new_df, df %>% 
                      filter(regexpr(value,tolower(EMPLOYER_NAME)) != -1))
  }
  return(new_df)
}
  
plot_input <- function(df, x_feature, fill_feature, metric,filter = FALSE, ...) {
  
  #Finding out the top across the entire range independent of the fill_feature e.g. Year
  top_x <- unlist(find_top(df,x_feature,metric, ...))
  
  filter_criteria <- interp(~x %in% y, .values = list(x = as.name(x_feature), y = top_x))
  arrange_criteria <- interp(~ desc(x), x = as.name(metric))

  if(filter == TRUE) {
    df %>%
      filter_(filter_criteria) -> df
  }
  
  #Grouping by not just x_feature but also fill_feature
  df %>% 
    group_by_(.dots=c(x_feature,fill_feature)) %>% 
    mutate(certified =ifelse(CASE_STATUS == "CERTIFIED",1,0)) -> core_df
  
   if(metric == "Wage") {
     return(core_df %>%
              mutate(METRIC = PREVAILING_WAGE))
   }  else {
     return(core_df %>%
              summarise(METRIC = ifelse(metric == "TotalApps", n(),sum(certified))))
   }
  
}
  
plot_output <- function(df, x_feature,fill_feature,metric) {  
  
  g <- ggplot(df, aes_string(x=x_feature,y="METRIC"))
  
  if(metric != "Wage") {
    return(g +
             geom_bar(stat = "identity", aes_string(fill = fill_feature), position = "dodge") + 
             coord_flip() + theme_gdocs() + scale_fill_gdocs())
  } else {
  return(g +
           geom_boxplot(aes_string(fill = fill_feature)) +
           coord_flip() + theme_gdocs() + scale_fill_gdocs())
  }
  
}

find_top <- function(df,x_feature,metric, Ntop) {
  
  arrange_criteria <- interp(~ desc(x), x = as.name(metric))
  
  df %>% 
    group_by_(x_feature) %>% 
    mutate(certified =ifelse(CASE_STATUS == "CERTIFIED",1,0)) %>%
    summarise(TotalApps = n(),
              Wage = median(PREVAILING_WAGE), 
              CertiApps = sum(certified)) %>%
      arrange_(arrange_criteria) -> top_df
  
  top_len <- min(dim(top_df)[1],Ntop)
  
  return(top_df[1:top_len,1])
}


