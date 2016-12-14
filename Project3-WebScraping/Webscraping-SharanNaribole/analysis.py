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

def word_locate(x,y):
    #x = player search index, y = reddit post title
    match = re.search(r'\b({0})\b'.format(x), y)
    res = 0
    if match:
        res = 1
    return res

def check_goal(title):
    check = 0
    keywords =['goal','scores','vs','against']
    keywords_bool =list(map(lambda keyword:word_locate(keyword,title),keywords))

    if(((keywords_bool[0]==True) or (keywords_bool[1]==True)) and ((keywords_bool[2]==True) or (keywords_bool[3]==True))):
        check = 1

    return check

#Define a main() function that prints a little greeting.
def main():
    clubs_df = pd.read_csv("clubs.csv",index_col=0)
    submission_metrics_df = pd.read_csv("submission_metrics.csv",index_col = 0)
    submission_metrics_df.sort_values('score',ascending=True, inplace=True)

    '''
    #---------------------------------------------------------------------------
    ## Submissions Analysis
    #---------------------------------------------------------------------------

    #Plot 1: :Scatter Plot b/w Diversity and Top Share with Point Size and Color function of Submission Score
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

    #Plot 2: :Scatter Plot b/w Diversity and Comments with Point Size and Color function of Submission Score
    low_scale = int(0*len(submission_metrics_df))
    up_scale = int(1.0*len(submission_metrics_df))
    #print(submission_metrics_df[low_scale:up_scale])
    plt.scatter(submission_metrics_df.diversity[low_scale:up_scale],submission_metrics_df.comments[low_scale:up_scale]
    ,s= submission_metrics_df.score[low_scale:up_scale]*0.1, c= submission_metrics_df.score[low_scale:up_scale])
    plt.title("Activity Analysis per Submission for /r/soccer Top posts \n Marker Size and Color varied by Submission Score")
    plt.xlabel("Flair Diversity")
    plt.ylabel("Number of Comments")
    plt.ylim((0,3000.0))
    #plt.savefig('results/scatter_submission.eps', format='eps', dpi=1000)
    plt.show()

    '''
    #---------------------------------------------------------------------------
    ## Clubs Analysis for TOP 6 Clubs with the highest average flair share percentage
    #---------------------------------------------------------------------------
    print(clubs_df.apply(lambda x:np.mean(x), axis=1).sort_values(ascending=False)[:25])
    top_clubs = list(clubs_df.apply(lambda x:np.mean(x), axis=1).sort_values(ascending=False)[:6].index)
    clubs_df = clubs_df.transpose()
    plt.figure()
    sns.boxplot(x=clubs_df[top_clubs])
    #clubs_df.boxplot(top_clubs)
    plt.ylim((0,25.0))
    plt.suptitle("Flair distribution in /r/soccer")
    plt.ylabel("Flair percentage share per submission")
    plt.xlabel("Flairs")
    plt.show()
    '''
    #---------------------------------------------------------------------------
    ## Comparing Metrics for Submissions:
    #---------------------------------------------------------------------------
    submission_metrics_df['title'] = submission_metrics_df.index
    match_thread_df = submission_metrics_df.groupby(lambda x: word_locate('Match Thread', x)).get_group(1)
    rest1_df = submission_metrics_df.groupby(lambda x: word_locate('Match Thread', x)).get_group(0)
    goals_df = submission_metrics_df.groupby(lambda x: check_goal(x)).get_group(1)
    rest2_df = submission_metrics_df.groupby(lambda x: check_goal(x)).get_group(0)
    rest_df = rest1_df.merge(rest2_df,how='inner',on='title')

    #Plot 1: Box Plot of Diversity
    plt.boxplot([goals_df['diversity'],match_thread_df['diversity'],rest_df['diversity_x']])
    plt.xticks([1,2,3],['Goals','Match Threads','Rest'])
    plt.title("Flair Diversity Analysis for /r/soccer top posts")
    plt.xlabel("Submission Type")
    plt.ylabel("Flair Diversity")
    plt.show()

    #Plot 2: Box Plot of Submission Score
    plt.boxplot([goals_df['score'],match_thread_df['score'],rest_df['score_x']])
    plt.xticks([1,2,3],['Goals','Match Threads','Rest'])
    plt.title("Submission Score Analysis for /r/soccer top posts")
    plt.xlabel("Submission Type")
    plt.ylabel("Submission Score")
    plt.ylim((0,4250))
    plt.show()

    #Plot 3: Box Plot of Top Share
    plt.boxplot([goals_df['top_share'],match_thread_df['top_share'],rest_df['top_share_x']])
    plt.xticks([1,2,3],['Goals','Match Threads','Rest'])
    plt.title("Top Flair Share Analysis for /r/soccer top posts")
    plt.xlabel("Submission Type")
    plt.ylabel("Top Flair Percentage Share")
    plt.ylim((0,15))
    plt.show()

    #Plot 4: Box Plot of Comments
    plt.boxplot([goals_df['comments'],match_thread_df['comments'],rest_df['comments_x']])
    plt.xticks([1,2,3],['Goals','Match Threads','Rest'])
    plt.title("Comments Analysis for /r/soccer top posts")
    plt.xlabel("Submission Type")
    plt.ylabel("Number of Comments")
    plt.ylim((0,2000))
    plt.show()
    '''

# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
