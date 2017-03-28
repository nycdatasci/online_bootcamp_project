library(dplyr)
library(ggplot2)
library(reshape2)
library(plotly)

# 1) Shooting distance stat.
shot_dist_data = read.csv('data/shot_distance_stats.csv')
rating_data = read.csv('data/off_rating_stat.csv')
rating_data['WIN.'] = rating_data['W'] / (rating_data['W'] + rating_data['L'])
rating_data['pf_or_not'] = 'No'

## 1.1) Teams got into playoff
for (season in levels(rating_data$Season)) {
  playoff_teams = 
    subset(shot_dist_data, Season.Type == 'POFF' & Season == season)
  
  rating_data[
    rating_data$Team %in% playoff_teams$Team & 
      rating_data$Season == season, ]['pf_or_not'] = 'Yes'
}

reg_pf_teams = rating_data[rating_data$pf_or_not == 'Yes', ]
reg_non_teams = rating_data[rating_data$pf_or_not == 'No' & 
                              rating_data$Season.Type == 'REG', ]

reg_teams_compare = data.frame(reg_pf_teams %>% 
                                 group_by(Season) %>% 
                                 summarise(pf_mean_0ft=mean(Less.than.8ft..usage..), 
                                           pf_mean_8ft=mean(X8.16.feet.usage..), 
                                           pf_mean_16ft=mean(X16.24.feet.usage..),
                                           pf_mean_24ft=mean(X24..feet.usage..), 
                                           pf_mean_shot_dist=mean(Avg..Shot.Dis..ft..)), 
                               reg_non_teams %>% 
                                 group_by(Season) %>% 
                                 summarise(non_mean_0ft=mean(Less.than.8ft..usage..), 
                                           non_mean_8ft=mean(X8.16.feet.usage..), 
                                           non_mean_16ft=mean(X16.24.feet.usage..),
                                           non_mean_24ft=mean(X24..feet.usage..), 
                                           non_mean_shot_dist=mean(Avg..Shot.Dis..ft..))
)

### TEMP: Average Shot Distance Plot
plot(c(2005, 2016), c(min(reg_teams_compare$pf_mean_shot_dist), max(reg_teams_compare$pf_mean_shot_dist)), type='n',
     xlab='Season', ylab=paste('Avg Shot Distance'), main=paste('Seasonal Average Shot Distance'))
lines(seq(2005, 2016), reg_teams_compare$pf_mean_shot_dist, col='red', lwd=2.5)
lines(seq(2005, 2016), reg_teams_compare$non_mean_shot_dist, col='green', lwd=2.5)
legend('topleft',
       c('Win Teams', 'Lose Teams'),
       lty=c(1, 1),
       lwd=c(2, 2),
       col=c('red', 'green'))


### TEMP: Offensive Rating vs. Win %
# ggplot()


### TEMP: Off Rating vs. Shot Distance Usage
print((lm(rating_data$OFFRTG ~ rating_data$Less.than.8ft..usage..)))
print((lm(rating_data$OFFRTG ~ rating_data$X8.16.feet.usage..)))
print((lm(rating_data$OFFRTG ~ rating_data$X16.24.feet.usage..)))
print((lm(rating_data$OFFRTG ~ rating_data$X24..feet.usage..)))

lm_eqn <- function(x, y) {
  m <- lm(y ~ x);
  eq <- substitute(italic(y) == a + b %.% italic(x), 
                   list(a = format(coef(m)[1], digits = 2), 
                        b = format(coef(m)[2], digits = 2)))
  as.character(as.expression(eq));                 
}

x_val = rating_data$Less.than.8ft..usage.. # Change this value for other plots.
x_lab = '< 8 ft' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
y_pos = min(rating_data$OFFRTG) + 2.5
ggplot(rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = 'glm', se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, rating_data$OFFRTG), parse = TRUE)


### TEMP: More Advanced Plots - Shot Usage Ratio vs. Offensive Rating
### Plot Shot Comb Ratio vs Offensive Rating
x_val = rating_data$X24..feet.usage../rating_data$Less.than.8ft..usage.. # Change this value for other plots.
x_lab = '(>24ft / <8ft)' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
ggplot(rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = "glm", se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, rating_data$OFFRTG), parse = TRUE)


x_val = rating_data$X24..feet.usage../rating_data$X8.16.feet.usage.. # Change this value for other plots.
x_lab = '(>24ft / 8-16ft)' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
ggplot(rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = "glm", se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, rating_data$OFFRTG), parse = TRUE)


x_val = rating_data$X24..feet.usage../rating_data$X16.24.feet.usage.. # Change this value for other plots.
x_lab = '(>24ft / 16-24ft)' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
ggplot(rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = "glm", se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, rating_data$OFFRTG), parse = TRUE)


### TEMP: shot ratio vs offensive rating. Not much insight here.
# ggplot(rating_data, aes(X16.24.feet.usage../X8.16.feet.usage.., OFFRTG)) +
#   geom_point() +
#   geom_smooth(method = "glm", se = TRUE)
# 
# ggplot(rating_data, aes(X16.24.feet.usage../Less.than.8ft..usage.., OFFRTG)) +
#   geom_point() +
#   geom_smooth(method = "glm", se = TRUE)
# 
# ggplot(rating_data, aes(X8.16.feet.usage../Less.than.8ft..usage.., OFFRTG)) +
#   geom_point() +
#   geom_smooth(method = "glm", se = TRUE)


### Making new features: ratio between different shot distance %
rating_data$ratio_24_0ft = rating_data$X24..feet.usage../rating_data$Less.than.8ft..usage..
rating_data$ratio_24_8ft = rating_data$X24..feet.usage../rating_data$X8.16.feet.usage..
rating_data$ratio_24_16ft = rating_data$X24..feet.usage../rating_data$X16.24.feet.usage..
rating_data$ratio_16_0ft = rating_data$X16.24.feet.usage../rating_data$Less.than.8ft..usage..
rating_data$ratio_16_8ft = rating_data$X16.24.feet.usage../rating_data$X8.16.feet.usage..
rating_data$ratio_8_0ft = rating_data$X8.16.feet.usage../rating_data$Less.than.8ft..usage..

### Clean anomaly from 'ratio_24_8ft' & 'ratio_24_16ft'.
cleaned_rating_data = rating_data[rating_data$ratio_24_8ft <= 2.5 & rating_data$ratio_24_16ft <= 2, ]

### TEMP
### Plot again the Shot Distance Ratio vs.Offensive Rating
print((lm(cleaned_rating_data$OFFRTG ~ cleaned_rating_data$ratio_24_8ft)))
x_val = cleaned_rating_data$ratio_24_8ft # Change this value for other plots.
x_lab = '(>24ft / 8-16ft)' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
ggplot(cleaned_rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = "glm", se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, cleaned_rating_data$OFFRTG), parse = TRUE)


print((lm(cleaned_rating_data$OFFRTG ~ cleaned_rating_data$ratio_24_16ft)))
x_val = cleaned_rating_data$ratio_24_16ft # Change this value for other plots.
x_lab = '(>24ft / 16-24ft)' # Change this too.
x_pos = max(x_val) - 0.1*max(x_val)
ggplot(cleaned_rating_data, aes(x_val, OFFRTG)) +
  geom_point() +
  xlab(x_lab) +
  ggtitle(paste('Offensive Rating vs.', x_lab, ' Shot Usage %')) +
  theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
  geom_smooth(method = "glm", se = TRUE) + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, cleaned_rating_data$OFFRTG), parse = TRUE)


## 1.2) Multivariate Linear Regression for Offensive Rating
model_x = data.frame(cleaned_rating_data$ratio_24_0ft,
                     cleaned_rating_data$ratio_24_8ft, 
                     cleaned_rating_data$ratio_24_16ft,
                     # cleaned_rating_data$ratio_16_0ft,
                     # cleaned_rating_data$ratio_16_8ft,
                     # cleaned_rating_data$ratio_8_0ft,
                     cleaned_rating_data$Less.than.8ft..usage.., 
                     cleaned_rating_data$X8.16.feet.usage.., 
                     cleaned_rating_data$X16.24.feet.usage.., 
                     cleaned_rating_data$X24..feet.usage..)
fit = lm(cleaned_rating_data$OFFRTG~., data=model_x)
# summary(fit)
# coef(fit)



server <- function(input, output, session) {
  output$plot <- renderPlot({
        data = switch(input$distance,
                      '< 8ft' = data.frame(reg_teams_compare$pf_mean_0ft, reg_teams_compare$non_mean_0ft),
                      '8-16ft' = data.frame(reg_teams_compare$pf_mean_8ft, reg_teams_compare$non_mean_8ft),
                      '16-24ft' = data.frame(reg_teams_compare$pf_mean_16ft, reg_teams_compare$non_mean_16ft),
                      '> 24ft' = data.frame(reg_teams_compare$pf_mean_24ft, reg_teams_compare$non_mean_24ft)
                      )

        plot(c(2005, 2016), c(min(data[, 1])-1.5, max(data[, 1])+1.5), type='n',
             xlab='Season', ylab=paste(input$distance, ' shot %'), main=paste('Shot % (Distance ', input$distance, ')'))
        lines(seq(2005, 2016), data[, 1], col='red', lwd=2.5)
        lines(seq(2005, 2016), data[, 2], col='green', lwd=2.5)
        legend('bottomright',
               c('Playoff Teams', 'Non-playoff Teams'),
               lty=c(1, 1),
               lwd=c(2, 2),
               col=c('red', 'green'))

      })
  output$plot_2 <- renderPlot({
    data = switch(input$distance,
                  '< 8ft' = data.frame(rating_data$Less.than.8ft..usage..),
                  '8-16ft' = data.frame(rating_data$X8.16.feet.usage..),
                  '16-24ft' = data.frame(rating_data$X16.24.feet.usage..),
                  '> 24ft' = data.frame(rating_data$X24..feet.usage..)
    )
    
    ggplot(rating_data, aes(data, OFFRTG)) +
      geom_point() +
      xlab(input$distance) +
      ggtitle(paste('Offensive Rating vs.', input$distance, ' Shot Usage %')) +
      theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
      geom_smooth(method = 'glm', se = TRUE)

  })

  output$plot_3 <- renderPlot({
    data = switch(input$distance,
                  '< 8ft' = data.frame(rating_data$Less.than.8ft..usage..),
                  '8-16ft' = data.frame(rating_data$X8.16.feet.usage..),
                  '16-24ft' = data.frame(rating_data$X16.24.feet.usage..),
                  '> 24ft' = data.frame(rating_data$X24..feet.usage..)
    )
    ggplot(rating_data, aes(data, WIN.)) +
      geom_point() +
      xlab(input$distance) +
      ggtitle(paste('Win % vs.', input$distance, ' Shot Usage %')) +
      theme(plot.title = element_text(size=16, lineheight=.8, face="bold", hjust=0.5)) +
      geom_smooth(method = 'glm', se = TRUE)

  })
  observe({
    updateSliderInput(session, "slider1", min=0, max=50, value = 50 - (input$slider2))
  })
  output$slider2 <- renderUI({
    sliderInput("slider2", label="8-16ft Shot Usage (%): ", min=0, max=50, value=50 - (input$slider1))
  })
  observe({
    updateSliderInput(session, "slider3", min=0, max=50, value = 50 - (input$slider4))
  })
  output$slider4 <- renderUI({
    sliderInput("slider4", label="> 24ft Shot Usage (%): ", min=0, max=50, value=50 - (input$slider3))
  })
  output$pred_rtg <- renderText({
    paste('Click submit to see your prediction!')
  })
  
  ntext <- eventReactive(input$predict, {
    new = data.frame(rating_data.Less.than.8ft..usage.. = input$slider1,
                     rating_data.X8.16.feet.usage.. = input$slider2,
                     rating_data.X16.24.feet.usage.. = input$slider3,
                     rating_data.X24..feet.usage.. = input$slider4)
    paste('< 8ft shot usage: ', input$slider1,  '%', '\n', 
          '8-16ft shot usage: ', 50-input$slider1, '%', '\n',
          '16-24ft shot usage: ', input$slider3,  '%', '\n',
          '> 24ft shot usage: ', 50-input$slider3, '%', '\n',
          'Predicted Offensive Rating: ', predict(fit, new))
  })
  output$nText <- renderText({
    ntext()
  })
  
  
  values <- reactiveValues()
  values$df <- 1
  values$pred <- 115.0
  values$zero <- 0
  values$eight <- 0
  values$sixteen <- 0
  values$twentyfour <- 0
  
  addData <- observeEvent(input$predict, {
    # your action button condition
    new = data.frame(rating_data.Less.than.8ft..usage.. = input$slider1,
                     rating_data.X8.16.feet.usage.. = input$slider2,
                     rating_data.X16.24.feet.usage.. = input$slider3,
                     rating_data.X24..feet.usage.. = input$slider4)
    
    # create the new line to be added from your inputs
    newLine <- isolate(data.frame(df=tail(values$df, 1) + 1, 
                                  pred=predict(fit, new), 
                                  zero=input$slider1, 
                                  eight=input$slider2, 
                                  sixteen=input$slider3, 
                                  twentyfour=input$slider4
                                  )
                       )
    
    # update your data
    tryCatch({
      isolate(values$df <- rbind(values$df, newLine$df))
      isolate(values$pred <- rbind(values$pred, newLine$pred))
      isolate(values$zero <- rbind(values$zero, newLine$zero))
      isolate(values$eight <- rbind(values$eight, newLine$eight))
      isolate(values$sixteen <- rbind(values$sixteen, newLine$sixteen))
      isolate(values$twentyfour <- rbind(values$twentyfour, newLine$twentyfour))
    }, 
      error = function(e) {
        print(paste('The error is: ', e))
      }
    )
  })

  output$pred_plot <- renderPlot({
    plot(x=values$df, y=values$pred, ylim=c(85, 120), 
         col = 'red', 
         xlab = 'Trials', 
         ylab = 'Predicted Offensive Rating', 
         main = 'Predict Offensive Rating Based On Shot Distance Usage (%)')
    text(values$df, 
         values$pred, 
         labels=paste('(', values$zero, ',', values$eight, ',', values$sixteen, ',', values$twentyfour, ')'), 
         cex=0.7, 
         pos=1)
  })
}

