import pandas as pd
import numpy as np
from scipy import stats

#Computes the metrics of percentage shares and Diversity from a given submission's flair_map raw data
def compute_flair_stats(flair_map_str):
    #returns flair stats from scipy
    taglines = flair_map_str[1:-1].replace("'","").split(',') #combination of commenter and flair
    #commenters = list(map(lambda tagline: tagline.split(': ')[0].strip(),taglines))
    flairs = [tagline.split(': ')[1].strip() for tagline in taglines]
    flairs = [x.replace("\"","") for x in flairs]
    flair_stats = stats.itemfreq(flairs)

    #Converting into percentage shares
    flair_stats[:,1] = [round(100*float(x)/len(flairs),3) for x in flair_stats[:,1]]
    return flair_stats

def score_conv(score):
    check_k = score.split('k')
    if(len(check_k)==2):
        return float(check_k[0])*1000
    else:
        return float(check_k[0])


#Define a main() function that prints a little greeting.
def main():
    reddit_df = pd.read_csv("flairs/reddit_data.csv") #DataFrame
    reddit_df.set_index('title',inplace=True)
    metrics_data = {'top_share': np.zeros(len(reddit_df.index)),
                    'diversity': np.zeros(len(reddit_df.index))}
    #reddit_df = pd.concat([reddit_df, pd.DataFrame(metrics_data,index=reddit_df.index)],axis=1)
    submission_metrics_df = pd.DataFrame(metrics_data,index=reddit_df.index)
    submission_metrics_df['score'] = [score_conv(x) for x in list(reddit_df['score'])]
    submission_metrics_df['comments'] = [float(x) for x in list(reddit_df['comments'])]

    clubs_df = pd.DataFrame() #Variable to store the DataFrame of percentage share of clubs for different submissions

    for index,row in reddit_df.iterrows():
        flair_stats = compute_flair_stats(row["flair_map"])
        #shares = [round(100*float(x)/len(flair_stats[:,1]),3) for x in flair_stats[:,1]]
        sorted_shares = sorted(flair_stats[:,1],reverse=True)

        #Percentage Share and Diversity metrics
        submission_metrics_df.loc[index,"top_share"] = sorted_shares[0]
        submission_metrics_df.loc[index,"diversity"] = len(sorted_shares)

        #Adding new data to clubs_df
        clubs_df_curr = pd.DataFrame(flair_stats[:,1], columns = [index],index = flair_stats[:,0])
        clubs_df = pd.concat([clubs_df,clubs_df_curr],axis=1)


    clubs_df.fillna(0.0,inplace=True) #entering zero percentage share for submissions with no participation
    #print(clubs_df)
    #print(clubs_df.apply(lambda x:np.mean(x), axis=1).sort_values(ascending=False))

    #Concat Submission Score

    clubs_df.to_csv("clubs.csv")
    submission_metrics_df.to_csv("submission_metrics.csv")

# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
