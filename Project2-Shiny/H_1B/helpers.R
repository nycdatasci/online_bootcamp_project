## Helper file

plot_input <- function(df, x_feature, fill_feature, metric,filter = FALSE, ...) {
  
  top_x <- unlist(find_top(df,x_feature,metric, ...))
  
  filter_criteria <- interp(~x %in% y, .values = list(x = as.name(x_feature), y = top_x))
  arrange_criteria <- interp(~ desc(x), x = as.name(metric))

  if(filter == TRUE) {
    df %>%
      filter_(filter_criteria) -> df
  }
  
  return(df %>% 
    group_by_(.dots=c(x_feature,fill_feature)) %>% 
    summarise(JOBS = n(), WAGE = median(PREVAILING_WAGE)) %>%
    arrange_(arrange_criteria))
}
  
plot_output <- function(df, x_feature,fill_feature, metric) {  
  
  g <- ggplot(df, aes_string(x=x_feature, y = metric)) +
    geom_bar(stat = "identity", aes_string(fill = fill_feature), position = "dodge") + 
    coord_flip() + theme_gdocs() + scale_fill_gdocs()
  
  return(g)
}

find_top <- function(df,x_feature,metric, top) {
  
  top <- (df %>% 
    group_by_(x_feature) %>% 
    summarise(METRIC = ifelse(metric == "JOBS", n(), median(PREVAILING_WAGE)) ) %>%
    arrange(desc(METRIC)))[1:top,1] 
  
  return(top)
}
