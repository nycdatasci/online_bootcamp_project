import numpy as np
import pandas as pd
import re
import matplotlib.pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")

#plt.style.use('ggplot')
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = 'Ubuntu'
#plt.rcParams['font.monospace'] = 'Ubuntu Mono'
plt.rcParams['font.size'] = 20
plt.rcParams['axes.labelsize'] = 20
plt.rcParams['axes.labelweight'] = 'bold'
plt.rcParams['xtick.labelsize'] = 20
plt.rcParams['ytick.labelsize'] = 20
plt.rcParams['legend.fontsize'] = 20
plt.rcParams['figure.titlesize'] = 24

#Define a main() function that prints a little greeting.
def main():
    clubs_df = pd.read_csv("clubs.csv",index_col=0)
    submission_metrics_df = pd.read_csv("submission_metrics.csv",index_col = 0)
    submission_metrics_df.sort_values('score',ascending=True, inplace=True)

    #---------------------------------------------------------------------------
    ## Submissions Analysis
    #---------------------------------------------------------------------------

    #Plot 1: Scatter Plot b/w Diversity and Top Share with Point Size and Color function of Submission Score
    low_scale = int(0*len(submission_metrics_df))
    up_scale = int(1.0*len(submission_metrics_df))
    #print(submission_metrics_df[low_scale:up_scale])
    plt.scatter(submission_metrics_df.diversity[low_scale:up_scale],submission_metrics_df.top_share[low_scale:up_scale]
    ,s= submission_metrics_df.score[low_scale:up_scale]*0.1, c= submission_metrics_df.score[low_scale:up_scale])
    plt.title("Flair Analysis per Submission for /r/soccer Top posts \n Marker Size and Color varied by Submission Score")
    plt.xlabel("Flair Diversity per Submission")
    plt.ylabel("Percentage of Top Flair per Submission")
    plt.ylim((0,80.0))
    #plt.savefig('results/scatter_submission.eps', format='eps', dpi=1000)
    #plt.show()


    #Finding the TOP 10 Clubs with the highest flair share percentage on average
    print(clubs_df.apply(lambda x:np.mean(x), axis=1).sort_values(ascending=False)[:25])
    top_clubs = list(clubs_df.apply(lambda x:np.mean(x), axis=1).sort_values(ascending=False)[:6].index)
    clubs_df = clubs_df.transpose()
    plt.figure()
    sns.violinplot(x=clubs_df[top_clubs])
    #clubs_df.boxplot(top_clubs)
    plt.ylim((-10,80.0))
    plt.show()


# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
