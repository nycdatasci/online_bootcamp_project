library(dplyr)
library(ggplot2)

nba_df = read.csv('NBA_Stat_copy.csv', sep = '\t')
# colnames(nba_df) = c('player', 'pos', '_min', 'FGM_A', '_3PM_A', 
#                      'FTM_A', 'plus_minus', 'OFF', 'DEF', 'TOT', 
#                      'AST', 'PF', 'ST', 'TO', 'BS', 'BA', 'PTS')
colnames(nba_df)
head(nba_df, 30)

# Set the min col to proper time format. Team data with min == 180, 200, 240, etc. becomes NA
class(as.POSIXct(as.character(nba_df$X_min), format = '%M:%S'))
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
team_df %>% ggplot(aes(X_3PA)) + geom_freqpoly(aes(color = WIN))
team_df %>% ggplot(aes(X_3PM)) + geom_freqpoly(aes(color = WIN))

# Histogram to compare win and lose for  field goal attempts/made
team_df %>% ggplot(aes(FGA)) + geom_freqpoly(aes(color = WIN))
team_df %>% ggplot(aes(FGM)) + geom_freqpoly(aes(color = WIN))

# Make a new column 'year', based on the first four string from column player
# Plot seasonal 3PT trend using game log stat
team_df$year = as.numeric(substr(team_df$player, 1, 4))
team_df %>% 
  group_by(year, WIN) %>% 
  summarise(avg_3PA = mean(X_3PA), avg_3PM = mean(X_3PM), avg_FGA = mean(FGA), avg_FGM = mean(FGM)) %>% 
  ggplot(aes(year, avg_3PM)) + geom_point(aes(color = WIN))


# Creating a date column using the player (Unique ID column)
team_df$date = as.POSIXct(substr(team_df$player, 1, 8), format = '%Y%m%d')

# Group and average 3PM by date, and plot the time series: not very insightful
team_df %>% 
  group_by(date) %>% 
  summarise(avg_3PM = mean(X_3PM)) %>% 
  ggplot(aes(date, avg_3PM)) + geom_point()






















