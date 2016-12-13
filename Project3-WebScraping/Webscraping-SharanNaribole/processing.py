import pandas as pd
import numpy as np
from scipy import stats
import re
import unicodedata


def word_locate(x,y):
    #x = player search index, y = reddit post title
    match = re.search(r'\b({0})\b'.format(x), y)
    res = 0
    if match:
        res = 1
    return res

#Computes the metrics of percentage shares and Diversity from a given submission's flair_map raw data
def compute_flair_stats(flair_map_str):
    #returns flair stats from scipy
    taglines = flair_map_str[1:-1].replace("'","").split(',') #combination of commenter and flair
    #commenters = list(map(lambda tagline: tagline.split(': ')[0].strip(),taglines))
    flairs = [tagline.split(': ')[1].strip() for tagline in taglines]
    flairs = [x.replace("\"","") for x in flairs]
    flair_stats = stats.itemfreq(flairs)

    #Converting into percentage shares
    flair_stats[:,1] = 100*flair_stats[:,1].astype(float)/len(flairs)
    return flair_stats

#Define a main() function that prints a little greeting.
def main():
    reddit_df = pd.read_csv("flairs/reddit_data.csv") #DataFrame
    metrics_data = {'top': np.zeros(len(reddit_df.index)),
                    'diversity': np.zeros(len(reddit_df.index))}
    reddit_df = pd.concat([reddit_df, pd.DataFrame(metrics_data,index=reddit_df.index)],axis=1)

    clubs_df = pd.DataFrame() #Variable to store the DataFrame of percentage share of clubs for different submissions

    for index,row in reddit_df.iterrows():
        flair_stats = compute_flair_stats(row["flair_map"])
        values = sorted([round(float(x),2) for x in flair_stats[:,1]],reverse=True)

        #Percentage Share and Diversity metrics
        reddit_df.loc[index,"top"] = values[0]
        reddit_df.loc[index,"diversity"] = len(values)

        #Adding new data to clubs_df
        clubs_df_curr = pd.DataFrame(values, columns = [index],index = flair_stats[:,0])
        clubs_df = pd.concat([clubs_df,clubs_df_curr],axis=1)


    clubs_df.fillna(0.0,inplace=True)
    #print(clubs_df.apply(lambda x:np.max(x), axis=1).sort_values(ascending=False))
    print(reddit_df)

# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
