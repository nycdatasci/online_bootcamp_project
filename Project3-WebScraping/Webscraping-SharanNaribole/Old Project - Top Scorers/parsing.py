import pandas as pd
import numpy as np
import datetime
import time
import praw
import re
import unicodedata
import matplotlib
import matplotlib.pyplot as plt

matplotlib.style.use('ggplot')

def percentile(n):
    def percentile_(x):
        return np.percentile(x, n)
    percentile_.__name__ = 'percentile_%s' % n
    return percentile_

def trunc(x):
    y = x.split('. ')
    if(len(y) == 1):
        return x
    else:
        return y[1]

def word_locate(x,y):
    #x = player search index, y = reddit post title
    match = re.search(r'\b({0})\b'.format(x), y)
    res = 0
    if match:
        res = 1
    return res

def day_delta(x,y):
    delta = pd.to_timedelta(y-x)
    match = re.search('\d+',str(delta))
    return int(match.group()) 

def week_delta(x,y):
    return day_delta(x,y)//7 #7 indicates number of days in a weeks
 

# Define a main() function that prints a little greeting.
def main():

    ##Extracting the Soccerway Top Scorers and creating search index names
    soccerway_df = pd.read_csv("soccerway.csv")
    new_index = soccerway_df['id_name']
    search_index = pd.DataFrame({'search_index':list(map(lambda x: trunc(x), list(new_index)))})
    soccerway_df = pd.concat([soccerway_df,search_index],axis = 1)
    soccerway_df.set_index('search_index',inplace=True)

    ##Loading Reddit Data, adding column Week and setting Title as Index column
    #Submission Creation Date to Index -> Transform it into Week 1, Week 2 etc.
    reddit_df = pd.read_csv("goals_data.csv")
    reddit_df = reddit_df.drop(['Unnamed: 0','index'],axis=1)

    #Earliest submission
    timestamps = list(map(lambda x: pd.to_datetime(x),list(reddit_df['time'])))
    earliest = min(timestamps)
    week_index = list(map(lambda x:week_delta(earliest,x),timestamps))
    reddit_df['week'] = pd.Series(week_index)
    #print(reddit_df)

    ##Creating a dictionary of DataFrame per Player
    reddit_df.set_index('title', inplace=True)
    player_dict = {}
    scoreless_players = []
    posts ={}
    for player in list(search_index['search_index']):
        group = reddit_df.groupby(lambda x: word_locate(player,x))
        if len(reddit_df.index)==len(group.get_group(0)):
            posts[player]=0
            scoreless_players.append(player)
            continue
        player_dict[player] = group.get_group(1)
        posts[player] = len(group.get_group(1))

    ##Hot Stars -  Top 5 Players based on number of posts in Reddit data
    soccerway_df['posts']=pd.Series(posts)
    soccerway_df = soccerway_df.sort_values('posts',ascending=False)
    hotstars = list(soccerway_df.index[:5])
    hotstars_dict= {k:v for (k,v) in player_dict.items() if k in hotstars}
    for hotstar in hotstars:
        hotstars_dict[hotstar] = hotstars_dict[hotstar].groupby('week').agg(['sum']).drop(['time','link'],axis=1)
    hotstars_df = pd.concat(hotstars_dict.values(),axis=0,keys=hotstars_dict.keys())
    hotstars_df.columns = ['comments','score']
    hotstars_df.fillna(0,inplace=True)
    print(hotstars_df)
    
    ##Hot Stars Comparison
    #Submission Score
    hotstars_df['score'].unstack(level=0).plot(kind='area',stacked=True)
    plt.xlabel('Week Index beginning from Aug 6 2016 to Dec 6 2016')
    plt.title("Hot Stars Comparison on /r/soccer ")
    plt.ylabel('Reddit Submission Score  - Weekly Mean')

    #Comments Activity
    hotstars_df['comments'].unstack(level=0).plot(kind='area',stacked=True)
    plt.xlabel('Week Index beginning from Aug 6 2016 to Dec 6 2016')
    plt.title("Hot Stars comparison on /r/soccer")
    plt.ylabel('Submission Comments - Weekly Mean')
    plt.show()
    
    #Global Stats
    #The goal is to get weekly numbers on all /r/soccer goal stats: Box plots

    '''
    #Boxplot
    fig, ax_new = plt.subplots(sharey=False)
    fig.suptitle("")
    ax_new.set_ylim([0, 1000])
    bp = reddit_df.boxplot(column = "score",by ="week",ax=ax_new)
    fig.suptitle('Reddit Overall /r/soccer Goal Statistics',backgroundcolor='grey', color='black')
    plt.xlabel('Week Index beginning from Aug 6 2016 to Dec 6 2016')
    plt.title("")
    plt.ylabel('Reddit Submission Score')
    plt.yticks(np.arange(0,1001,100))
    #plt.show()
    
    #Histogram
    plt.figure()
    plt.hist(list(reddit_df['score']),bins = 500)
    plt.xlim([0,1000])
    plt.title('Reddit Overall /r/soccer Goals Histogram for Aug 6 2016 to Dec 6 2016 Bins = 500')
    plt.xlabel('Reddit Submission Score')
    #plt.show()
    plt.show()
    '''
    
    ##Grouping Players into Leagues
    #Aggregating Player Submission Scores into One frame
    soccerway_df.reset_index(inplace=True)
    leagues = soccerway_df['league'].unique()
    league_players = {}
    league_metrics = {}
    for league_name in leagues:
        league_players[league_name] = list(soccerway_df.loc[soccerway_df.league==league_name,'search_index'])
        league_df = pd.DataFrame()
        for player in league_players[league_name]:
            if player in scoreless_players:
                continue
            league_df = league_df.add(player_dict[player].groupby('week').agg('sum'),fill_value=0)
        league_metrics[league_name] = league_df
    league_metrics_df = pd.concat(league_metrics.values(),axis=0,keys=league_metrics.keys())
    league_metrics_df.fillna(0,inplace=True)
    #print(league_metrics_df.score)

    ##Leagues Comparison
    #Submission Score
    league_metrics_df['score'].unstack(level=0).plot(kind='area',stacked=True)
    plt.xlabel('Week Index beginning from Aug 6 2016 to Dec 6 2016')
    plt.title("League Comparison on /r/soccer - Weekly Mean")
    plt.ylabel('Reddit Submission Score')

    #Comments Activity
    league_metrics_df['comments'].unstack(level=0).plot(kind='area',stacked=True)
    plt.xlabel('Week Index beginning from Aug 6 2016 to Dec 6 2016')
    plt.title("League comparison on /r/soccer")
    plt.ylabel('Submission Comments - Weekly Mean')
    plt.show()
    

    
    
# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
