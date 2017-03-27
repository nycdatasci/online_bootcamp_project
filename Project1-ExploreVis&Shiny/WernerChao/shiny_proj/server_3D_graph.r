# ### 3D Plots.
# fit_1 = lm(data = rating_data, 
#            OFFRTG ~ X24..feet.usage.. + Less.than.8ft..usage..)
# 
# #Setup Axis
# graph_reso <- 0.05
# axis_x <- seq(min(rating_data$Less.than.8ft..usage..), max(rating_data$Less.than.8ft..usage..), by = graph_reso)
# axis_y <- seq(min(rating_data$X24..feet.usage..), max(rating_data$X24..feet.usage..), by = graph_reso)
# 
# #Sample points
# lm_surface <- expand.grid(Less.than.8ft..usage.. = axis_x, 
#                           X24..feet.usage.. = axis_y, 
#                           KEEP.OUT.ATTRS = F)
# lm_surface$OFFRTG <- predict.lm(fit_1, newdata=lm_surface, se=TRUE)
# lm_surface <- acast(lm_surface, Less.than.8ft..usage.. ~ X24..feet.usage.., value.var = "OFFRTG")
# 
# p <- plot_ly(rating_data, 
#              x = ~Less.than.8ft..usage.., 
#              y = ~X24..feet.usage.., 
#              z = ~OFFRTG, 
#              type = 'scatter3d', 
#              mode = 'markers', 
#              marker = list(color = hcolors)) %>%
#   add_markers() %>%
#   layout(scene = list(xaxis = list(title = '<8ft'),
#                       yaxis = list(title = '>24ft'),
#                       zaxis = list(title = 'Off Rtg.')))
# 
# p %>% add_trace(z = lm_surface, 
#                 type = "surface")
# 
# p_2 <- plot_ly(z = lm_surface, 
#                x = axis_x, 
#                y = axis_y) %>% add_surface()
# p_2
