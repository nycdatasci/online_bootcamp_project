library(dplyr)
library(ggplot2)

nba_df = read.csv('NBA_Stat_new.csv', sep = '\t')
colnames(nba_df) = c('player', 'pos', 'X_min', 'FGM_A', 'X_3PM_A',
                     'FTM_A', 'plus_minus', 'OFF', 'DEF', 'TOT',
                     'AST', 'PF', 'ST', 'TO', 'BS', 'BA', 'PTS')
colnames(nba_df)
head(nba_df, 30)

# Set the min col to proper time format. Team data with min == 180, 200, 240, etc. becomes NA
head(as.POSIXct(as.character(nba_df$X_min), format = '%M:%S'))
nba_df$X_min= as.POSIXct(as.character(nba_df$X_min), format = '%M:%S')

# Check what the dataframe looks like use this:
head(filter(nba_df, is.na(nba_df$X_min)), 3)

# Split the 3PM_A into 3PM and 3PA. Similarly, for FGM and FGA
nba_df$X_3PM = as.numeric(gsub("(.*)\\-(.*)","\\1",nba_df$X_3PM_A))
nba_df$X_3PA = as.numeric(gsub("(.*)\\-(.*)","\\2",nba_df$X_3PM_A))
nba_df$FGM = as.numeric(gsub("(.*)\\-(.*)","\\1",nba_df$FGM_A))
nba_df$FGA = as.numeric(gsub("(.*)\\-(.*)","\\2",nba_df$FGM_A))

nba_df %>% 
  filter(is.na(nba_df$X_min)) %>% 
  ggplot(aes(FGA, PTS)) + geom_point()

### Do winning teams take more 3 point shots?
team_df = nba_df %>% filter(is.na(nba_df$X_min))

# Team points minus game total points from both teams, if it's +VE then the team won, if -VE then team lost
# Create a new column, WIN, to label the winning team
team_df = team_df %>% group_by(player) %>% mutate(WIN = (PTS - mean(PTS)) > 0)

# Histogram to compare both winning and losing team for their 3 point shot attempts/made
team_df %>% ggplot(aes(X_3PA)) + geom_freqpoly(aes(color = WIN)) + 
  labs(x='3 Point Attempt', y='Count') + ggtitle('Histogram of 3PAttempt') + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))
team_df %>% ggplot(aes(X_3PM)) + geom_freqpoly(aes(color = WIN)) + 
  labs(x='3 Point Made', y='Count') + ggtitle('Histogram of 3PMade') + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))

# Histogram to compare win and lose for field goal attempts/made
team_df %>% ggplot(aes(FGA)) + geom_freqpoly(aes(color = WIN)) + 
  labs(x='2 Point Attempt', y='Count') + ggtitle('Histogram of 2PAttempt') + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))
team_df %>% ggplot(aes(FGM)) + geom_freqpoly(aes(color = WIN)) + 
  labs(x='2 Point Made', y='Count') + ggtitle('Histogram of 2PMade') + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))

# Make a new column 'year', based on the first four string from column player
# Plot Annual 3PT trend using game log stat
team_df$year = as.POSIXct(as.numeric(substr(team_df$player, 1, 4)))
team_df %>% 
  group_by(year, WIN) %>% 
  summarise(avg_3PA = mean(X_3PA), avg_3PM = mean(X_3PM), avg_FGA = mean(FGA), avg_FGM = mean(FGM), avg_PTS = mean(PTS)) %>% 
  ggplot(aes(year, avg_3PM)) + geom_point(aes(color = WIN), size=5) + 
  ylim(5, 10) +
  labs(x='Year', y='Average 3 Point Made') + ggtitle('Annual Average of 3 Point Made') + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))


# Creating a 'date' column using the player (Unique ID column)
team_df$date = as.POSIXct(substr(team_df$player, 1, 8), format = '%Y%m%d')

# Group and average 3PM by date, and plot the time series: not very insightful
team_df %>% 
  group_by(date, WIN) %>% 
  summarise(avg_3PM = mean(X_3PM)) %>% 
  ggplot(aes(date, avg_3PM)) + geom_point(aes(color = WIN))

# Trying to plot daily average plot and yearly average plot together: DID NOT WORK!
# Making the dataframes first
average_shots = team_df %>% 
  group_by(year, WIN) %>% 
  summarise(avg_3PA = mean(X_3PA), avg_3PM = mean(X_3PM), avg_FGA = mean(FGA), avg_FGM = mean(FGM))
shots_by_date = team_df %>% 
  group_by(date, WIN) %>% 
  summarise(avg_3PA = mean(X_3PA), avg_3PM = mean(X_3PM))
shots_by_date$seq = seq(1, dim(shots_by_date)[1])

# This is the eqn. to show on plots
lm_eqn <- function(x, y) {
  m <- lm(y ~ x);
  eq <- substitute(italic(y) == a + b %.% italic(x), 
                   list(a = format(coef(m)[1], digits = 2), 
                        b = format(coef(m)[2], digits = 2)))
  as.character(as.expression(eq));                 
}

# Trying to plots daily average vs annual average together: DID NOT WORK!
# This is daily average.
plot(x=shots_by_date$seq, y=shots_by_date$avg_3PM, col='green')

x_val = shots_by_date$seq # Made the daily average to show a fitted line.
x_pos = max(x_val) - 0.1*max(x_val)
y_pos = min(shots_by_date$avg_3PA) + 2.5
ggplot(shots_by_date, aes(seq, avg_3PA)) + geom_point(aes(color = WIN)) + 
  geom_smooth(method = "glm", se = TRUE) + 
  ylim(10, 35) +
  ggtitle('Time Series Plot of Average 3 Point Attempt') + 
  labs(x='Days (day 0 first game in 2010)', y='Average 3 Point Attempt') + 
  geom_text(x = x_pos, y = y_pos, size=8, color='red', label = lm_eqn(x_val, shots_by_date$avg_3PA), parse = TRUE) + 
  theme(plot.title = element_text(hjust = 0.5), text = element_text(size=25))

# Annual average.
plot(x=average_shots$year, y=average_shots$avg_3PA, col='red')

# Plot 3PA vs. FGA
team_df %>% ggplot(aes(X_3PA, FGA)) + geom_point()

# Matrix scatterplots of some useful variables
team_df %>% ggplot(aes(value)) + facet_wrap(~ key, scales = 'free') + geom_histogram()
team_df_clean = team_df[, c('AST', 'PTS', 'X_3PM', 'X_3PA', 'FGM', 'FGA')]
head(team_df_clean)
pairs(team_df_clean)

# Remake the dataframe team_df_clean to include more variables
team_df_clean = team_df[, c('OFF', 'DEF', 'BS', 'TO', 'ST', 'AST', 'PTS', 'X_3PM', 'X_3PA', 'FGM', 'FGA')]

# Screeplot for clustering
wssplot = function(data, nc = 15, seed = 0) {
  wss = (nrow(data) - 1) * sum(apply(data, 2, var))
  for (i in 2:nc) {
    set.seed(seed)
    wss[i] = sum(kmeans(data, centers = i, iter.max = 100, nstart = 100)$withinss)
  }
  plot(1:nc, wss, type = "b",
       xlab = "Number of Clusters",
       ylab = "Within-Cluster Variance",
       main = "Scree Plot for the K-Means Procedure")
}

# Doing clustering here. 2 Clusters.
wssplot(team_df_clean)
km.team_df_clean = kmeans(team_df_clean, centers = 2, nstart = 100)
km.team_df_clean$centers

plot(team_df_clean$X_3PA, team_df_clean$FGA,
     xlab = "X_3PA", ylab = "FGA",
     main = "K-Means", col = km.team_df_clean$cluster)


# Want to do t-test on "winning team attempt more 3 point shots"
# Null hypothesis: "winning and losing teams attempt the same # of 3 point shots"
win_team_df = team_df %>% filter(WIN == TRUE)
lose_team_df = team_df %>% filter(WIN == FALSE)
t.test(win_team_df$X_3PA, lose_team_df$X_3PA)
t.test(win_team_df$X_3PM, lose_team_df$X_3PM)

# Winning team attempts more 3 point shots on annual basis
win_team_df = team_df %>% filter(WIN == TRUE, year=='2014')
lose_team_df = team_df %>% filter(WIN == FALSE, year=='2014')
t.test(win_team_df$X_3PA, lose_team_df$X_3PA)
t.test(win_team_df$X_3PM, lose_team_df$X_3PM)

# Does this year really have more 3-point shot than last year?
this_year_team_df = team_df %>% filter(year=='2016')
last_year_team_df = team_df %>% filter(year=='2015')
t.test(this_year_team_df$X_3PA, last_year_team_df$X_3PA)







