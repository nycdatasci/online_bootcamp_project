import pandas as pd
import datetime as dt
import time
import praw
import unicodedata

def decompose(x):
    x = unicodedata.normalize('NFD',x).encode('ascii','ignore')
    return x.decode("utf-8")

# Follow https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example to get Authorization to collect Reddit Data
reddit = praw.Reddit(user_agent = 'username reddit',client_id = 'xxxx',client_secret = 'xxxx',username='xxxx',password='xxxx')
#print(reddit.user.me())

start_date = dt.date(2016,8,6)
start_time = int(time.mktime(start_date.timetuple()))
end_date = dt.date(2016,12,6)
end_time = int(time.mktime(end_date.timetuple()))

subreddit = reddit.subreddit('soccer')
#Typical terms in a submission on /r/soccer for Goals
query = "(or title:'goal' title:'scores') (or title:'vs' title:'against')"

#List of Submission instances
submissions = subreddit.submissions(start = start_time, end = end_time, extra_query=query)

#DataFrame to be used for reddit data collection
goals_data = {'time':[],
               'title':[],
               'link': [],
               'comments':[],
               'score':[]}
goals_df = pd.DataFrame(goals_data)               

#Iterating over the submissions
for submission in submissions:
    new_df = pd.DataFrame({'time':[time.ctime(submission.created)],
               'title':[decompose(submission.title)],
               'comments': [len(submission.comments.list())],
               'link': [submission.permalink],
               'score':[submission.score]})
    goals_df = pd.concat([goals_df,new_df],axis=0)
    print("Submission Title: ",submission.title)
    print("Submission Score: ", submission.score)
    print("Submission Date: ", time.ctime(submission.created))
    print("---------------------------------\n")

goals_df = goals_df.reset_index()
print(goals_df)    
print("---------------------------------\n")

#Storing data in a csv
goals_df.to_csv("goals_data.csv")

