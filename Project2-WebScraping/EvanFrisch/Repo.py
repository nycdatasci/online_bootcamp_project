# from github import Github
from textblob import TextBlob
from textstat.textstat import textstat
import requests
from bs4 import BeautifulSoup
# from lxml import html
from markdown import markdown
import pandas as pd
import datetime
from bokeh.plotting import figure
from bokeh.models import Range1d, DatetimeTickFormatter

class Repo:

    def __init__(self, raw_repo):
        self.repo = self.set_metrics(raw_repo)

    def set_readme(self, raw_repo):
        readme_content = None
        try:
            readme = raw_repo.get_readme()
            if readme:
                readme_content = readme.decoded_content
                readme_html = markdown(readme_content)
                readme_content = ''.join(BeautifulSoup(readme_html, 'lxml').findAll(text = True))
        except Exception as exc:
            pass

        self.readme = readme_content

    def set_commits(self, raw_repo):
        self.commit_messages = []
        self.committers = set() # store unique committers
        try:
            commits = raw_repo.get_commits()
            for commit in commits:
                self.committers.add(commit.committer.id)
                self.commit_messages.append('"'+commit.commit.message+'"')
        except:
            pass
        
        
    def set_commit_dataframe(self, raw_repo):
        commit_nested_list = []  # nested list of commits for this repo
        try:
            commits = raw_repo.get_commits()
            for commit in commits:
                # exclude commits made automatically by GitHub's web-flow bot
                if commit.committer.login != 'web-flow':
                    current_commit = [ commit.commit.author.date, commit.commit.message, commit.committer.login, commit.committer.id ]
                    commit_nested_list.append(current_commit)
        except:
            print "Unable to obtain commits"
            pass

        #print commit_nested_list

        self.commit_dataframe = pd.DataFrame(commit_nested_list,
                                            columns=['commit_datetime', 'commit_message', 'committer_login', 'committer_id'])

        #reorder by commit timestamp
        self.commit_dataframe.sort_values(by = 'commit_datetime', ascending = True, inplace = True)
        self.commit_dataframe.index = range(1, len(self.commit_dataframe) + 1)

        #print self.commit_dataframe.head()


    def set_contributors(self, raw_repo):
        self.contributor_set = set()
        contributors = raw_repo.get_contributors()

        for contributor in contributors:
            self.contributor_set.add(contributor.id)

    def set_pull_request_commenters(self, raw_repo):
        self.pull_request_commenter_set = set()
        pull_request_comments = raw_repo.get_pulls_comments()
        for pull_request_comment in pull_request_comments:
            self.pull_request_commenter_set.add(pull_request_comment.user.id)

    def set_issue_comment_dataframe(self, raw_repo):
        comment_nested_list = []  # nested list of commits for this repo
        try:
            issue_comments = raw_repo.get_issues_comments()
            for issue_comment in issue_comments:
                # exclude comments made automatically by GitHub's web-flow bot'
                if issue_comment.user.login != 'web-flow':
                    current_comment = [ issue_comment.created_at, issue_comment.id,
                                        issue_comment.body, issue_comment.user.login,
                                        issue_comment.user.id ]
                    comment_nested_list.append(current_comment)
        except:
            print "Unable to obtain comments"
            pass

        #print comment_nested_list

        self.issue_comment_dataframe = pd.DataFrame(comment_nested_list,
                                            columns=['comment_datetime', 'comment_id', 'comment_text', 'commenter_login', 'commenter_id'])

        #reorder by comment timestamp
        self.issue_comment_dataframe.sort_values(by = 'comment_datetime', ascending = True, inplace = True)
        self.issue_comment_dataframe.index = range(1, len(self.issue_comment_dataframe) + 1)

        print "issue_comment_dataframe"
        print self.issue_comment_dataframe.head()


    def set_issue_commenters(self, raw_repo):
        self.issue_commenter_set = set()
        issue_comments = raw_repo.get_issues_comments()
        for issue_comment in issue_comments:
            self.issue_commenter_set.add(issue_comment.user.id)

    def set_unique_contributors(self, raw_repo):
        self.unique_contributors = self.committers | self.contributor_set | self.pull_request_commenter_set | self.issue_commenter_set

    def set_maintenance_metrics(self, raw_repo):
        print raw_repo.full_name
        try:
            result = requests.get("http://isitmaintained.com/project/"+raw_repo.full_name)
            if result.status_code == 200:
                content = result.content
                soup = BeautifulSoup(content, 'lxml')
                i = 0
                for content_well in soup.find_all("div", "well"):
                    result = content_well.find("strong").contents[0]
                    if i == 0:
                        self.median_resolution_time = result
                    elif i == 1:
                        self.percent_open_issues = result
                    else:
                        break

                    i += 1
            else:
                print "Maintenance page not found"
        except:
            print "Unable to get maintenance metrics"

    def set_topics(self):
        self.topics = "No topics found"
        try:
            result = requests.get(self.url)
            print self.url
            print result
            if result.status_code == 200:
                print "result code was 200"
                content = result.content
                soup = BeautifulSoup(content, 'lxml')
                topics_div = soup.find("div", "list-topics-container")
                topics_div.find_all("a")[0].contents[0].strip()
                topic_list = [topic.contents[0].strip() for topic in topics_div.find_all("a")]
                self.topics = ", ".join(topic_list)
            else:
                print "GitHub repository home page not found"
        except:
            print "Unable to get topic list"

    def set_metrics(self, raw_repo):
        self.name = raw_repo.name
        self.full_name = raw_repo.full_name
        self.url = raw_repo.html_url
        self.created_at = raw_repo.created_at
        self.stargazers_count = raw_repo.stargazers_count
        self.description = raw_repo.description
        self.language = raw_repo.language
        self.set_readme(raw_repo)
        self.set_maintenance_metrics(raw_repo)
        self.set_commit_dataframe(raw_repo)
        self.set_issue_comment_dataframe(raw_repo)
        self.set_topics()

    def set_xaxis_format(self, plot):
        plot.xaxis.formatter = DatetimeTickFormatter(#formats = dict(
            hours = ["%b %Y"],
            days = ["%b %Y"],
            months = ["%b %Y"],
            years = ["%b %Y"])
        #))
        return plot


    def get_name(self):
        return self.name

    def get_full_name(self):
        return self.full_name

    def get_url(self):
        return self.url

    def get_created_at(self):
        return self.created_at

    def get_description(self):
        return self.description

    def get_readme(self):
        return self.readme

    def get_stargazers_count(self):
        return self.stargazers_count

    def get_commit_messages(self):
        return self.commit_messages

    def get_committer_count(self):
        return len(self.committers)

    def get_commit_count(self):
        return len(self.commit_messages)

    def get_contributors(self):
        return self.contributor_set

    def get_contributor_count(self):
        return len(self.contributor_set)

    def get_pull_request_commenter_count(self):
        return len(self.pull_request_commenter_set)

    def get_issue_commenter_count(self):
        return len(self.issue_commenter_set)

    def get_unique_contributors(self):
        return len(self.unique_contributors)
    
    def get_description_polarity(self):
        if self.description:
            return TextBlob(self.description).polarity
        else:
            return None

    def get_description_subjectivity(self):
        if self.description:
            return TextBlob(self.description).subjectivity
        else:
            return None

    def get_description_flesch_reading_ease(self):
        if self.description:
            return textstat.flesch_reading_ease(self.description)
        else:
            return None

    def get_description_composite_grade_level(self):
        if self.description:
            return textstat.text_standard(self.description)
        else:
            return None

    def get_description_noun_phrases(self):
        if self.description:
            print self.description
            return TextBlob(self.description).noun_phrases
        else:
            return None

    def get_readme_polarity(self):
        if self.readme:
            return TextBlob(self.readme).polarity
        else:
            return None

    def get_readme_subjectivity(self):
        if self.readme:
            return TextBlob(self.readme).subjectivity
        else:
            return None

    def get_readme_flesch_reading_ease(self):
        if self.readme:
            return textstat.flesch_reading_ease(self.readme)
        else:
            return None

    def get_readme_composite_grade_level(self):
        if self.readme:
            return textstat.text_standard(self.readme)
        else:
            return None

    def get_readme_noun_phrases(self):
        if self.readme:
            #return TextBlob(self.readme).noun_phrases
            return list(set(TextBlob(self.readme).noun_phrases))
        else:
            return None

    def get_median_resolution_time(self):
        return self.median_resolution_time

    def get_percent_open_issues(self):
        return self.percent_open_issues

    def get_language(self):
        return self.language

    def get_topics(self):
        return self.topics

    def get_commit_timeseries(self):

        monthly_commit_count = self.commit_dataframe.set_index('commit_datetime').resample('MS').size()

        start_date = datetime.datetime.utcfromtimestamp(monthly_commit_count.index.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1,1))

        max_y = monthly_commit_count.values.max()

        yrange = Range1d(start=0, end=max_y * 1.2)

        TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
        plot = figure(title="Monthly Number of Commits",
                      x_axis_label = "Month",
                      y_axis_label = "Commits",
                      x_range = xrange,
                      y_range = yrange,
                      x_axis_type = "datetime",
                      tools=TOOLS,
                      plot_width = 600,
                      plot_height = 300,
                      responsive = True)

        plot.vbar(x = monthly_commit_count.index,
                  width = 0.8*2.62974383e9,
                  bottom = 0,
                  top = monthly_commit_count.values,
                  color="#337ab7")

        plot = self.set_xaxis_format(plot)

        return plot

    def get_comment_timeseries(self):
        issue_comment_df = self.issue_comment_dataframe
        issue_comment_df.set_index('comment_datetime', inplace = True)

        issue_comment_df['polarity'] = issue_comment_df['comment_text'].apply(lambda x: TextBlob(x).polarity)

        start_date = pd.Timestamp(min(issue_comment_df.index.values)).to_datetime()

        today = datetime.date.today()

        xrange = Range1d(start=datetime.date(start_date.year, start_date.month, start_date.day),
                         end=datetime.date(today.year, today.month, today.day))

        yrange = Range1d(start = -1, end = 1)

        TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
        plot = figure(title="Issue Comment Polarity", x_axis_label="Date", y_axis_label="Polarity",
                      x_range=xrange, x_axis_type="datetime",
                      y_range = yrange,
                      tools=TOOLS, plot_width=600, plot_height=300, responsive=True)

        plot.line(  x=issue_comment_df.index,
                    y=issue_comment_df.polarity,
                    line_width = 2,
                    color="#337ab7",
                    #color="#CAB2D6",
                    alpha = 0.5)

        plot = self.set_xaxis_format(plot)

        return plot

    def get_text_statistics(self):
        html = '''<div class="list-group">
				 <a href="#" class="list-group-item active">Repository Text Metrics</a>
				<div class="list-group-item">
				    <h4 class="list-group-item-heading">Description</h4>
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{0}</span>Polarity
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{1}</span>Subjectivity
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{2}</span>Flesch Reading Ease
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{3}</span>Composite Grade Level
				</div>
				<div class="list-group-item">
				    <h4 class="list-group-item-heading">Readme</h4>
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{4}</span>Polarity
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{5}</span>Subjectivity
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{6}</span>Flesch Reading Ease
				</div>
				<div class="list-group-item" style="text-indent: 1em;">
					<span class="badge" style="text-indent: 0;">{7}</span>Composite Grade Level
				</div>
				<a class="list-group-item active"><span class="badge"></span></a>
			</div>'''.format(str("%.2f" % self.get_description_polarity()),
                             str("%.2f" % self.get_description_subjectivity()),
                             self.get_description_flesch_reading_ease(),
                             self.get_description_composite_grade_level(),
                             str("%.2f" % self.get_readme_polarity()),
                             str("%.2f" % self.get_readme_subjectivity()),
                             self.get_readme_flesch_reading_ease(),
                             self.get_readme_composite_grade_level())
        return html

    def get_maintenance_statistics(self):
        html = '''<div class="list-group">
                 <a href="#" class="list-group-item active">Maintenance Metrics</a>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{0}</span>Open Issues Percentage
                </div>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{1}</span>Median Resolution Time
                </div>
                <a class="list-group-item active"><span class="badge"></span>Maintenance indicators calculated by and
                    scraped from IsItMaintained.com</a>
            </div>'''.format(str("%s" % self.get_percent_open_issues()),
                             str("%s" % self.get_median_resolution_time()))
        return html

    def get_summary_information(self):
        html = '''<div class="list-group">
                 <a href="#" class="list-group-item active">Summary Information</a>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{0}</span>Language
                </div>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{1}</span>Tags
                </div>
                <a class="list-group-item active"><span class="badge">{2}</span>Star Count</a>
            </div>'''.format(str("%s" % self.get_language()),
                             str("%s" % self.get_topics()),
                             str("%s" % self.get_stargazers_count()))
        return html

    def get_text_key_phrases(self):
        html = '''<div class="list-group">
    				 <a href="#" class="list-group-item active">Repository Keywords</a>
    				<div class="list-group-item">
    				    <h4 class="list-group-item-heading">Description</h4>
    				</div>
    				<div class="list-group-item">{0}</div>
    				<div class="list-group-item">
    				    <h4 class="list-group-item-heading">Readme</h4>
    				</div>
    				<div class="list-group-item">{1}</div>
    			</div>'''.format("<br />".join(self.get_description_noun_phrases()),
                                 "<br />".join(self.get_readme_noun_phrases()))
        return html


    def get_unique_committer_by_month(self):
        commits = self.commit_dataframe
        commits['month_start'] = commits.commit_datetime.apply(lambda x: datetime.datetime(x.date().year, x.date().month, 1))

        # drop unneeded columns
        commits.drop('commit_message', axis = 1, inplace = True)
        commits.drop('committer_login', axis = 1, inplace = True)
        commits.drop('commit_datetime', axis = 1, inplace = True)
        unique_committer_by_month = commits.groupby('month_start').agg({"committer_id": lambda x: x.nunique()})
        # rename column
        unique_committer_by_month = unique_committer_by_month.rename(columns = {'committer_id': 'unique_committer_count'})
        unique_committer_by_month.reset_index(inplace = True)

        print unique_committer_by_month
        return unique_committer_by_month


    def get_unique_issue_commenter_by_month(self):
        comments = self.issue_comment_dataframe

        comments['month_start'] = comments.index.to_series().apply(lambda x: datetime.datetime(x.year, x.month, 1))

        # drop unneeded columns
        comments.drop('comment_id', axis = 1, inplace = True)
        comments.drop('comment_text', axis = 1, inplace = True)
        comments.drop('commenter_login', axis = 1, inplace = True)

        print "comments groupby results"
        unique_commenter_by_month = comments.groupby('month_start').agg({"commenter_id": lambda x: x.nunique()})
        # rename column
        unique_commenter_by_month = unique_commenter_by_month.rename(columns = {'commenter_id': 'unique_commenter_count'})
        unique_commenter_by_month.reset_index(inplace = True)

        print unique_commenter_by_month
        return unique_commenter_by_month

    def get_unique_committer_barchart(self):
        unique_committer_by_month = self.get_unique_committer_by_month()

        start_date = datetime.datetime.utcfromtimestamp(unique_committer_by_month.month_start.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1, 1))

        TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
        plot = figure(title="Monthly Number of Unique Committers",
                      x_axis_label = "Month",
                      y_axis_label = "Unique Committers",
                      tools=TOOLS,
                      x_range=xrange,
                      x_axis_type="datetime",
                      plot_width = 600,
                      plot_height = 300,
                      responsive = True)

        plot.vbar(x = unique_committer_by_month.month_start,
                  width = 0.8*2.62974383e9,
                  bottom = 0,
                  top = unique_committer_by_month.unique_committer_count,
                  color="#337ab7")
                  # color="#CAB2D6")

        plot = self.set_xaxis_format(plot)

        return plot

    def get_unique_contributor_barchart(self):
        unique_committer_by_month = self.get_unique_committer_by_month()
        unique_issue_commenter_by_month = self.get_unique_issue_commenter_by_month()
        #print unique_committer_by_month
        contributors = pd.merge(unique_committer_by_month, unique_issue_commenter_by_month, on = "month_start",
                                how = "outer")

        contributors = contributors.fillna(0)
        print "contributors"
        print contributors

        start_date = datetime.datetime.utcfromtimestamp(contributors.month_start.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1,1))

        max_y = contributors[['unique_committer_count','unique_commenter_count']].values.max()

        yrange = Range1d(start = 0, end = max_y*1.2)

        TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
        plot = figure(title="Monthly Number of Unique Contributors",
                      x_axis_label = "Month",
                      y_axis_label = "Unique Contributors",
                      tools=TOOLS,
                      x_range=xrange,
                      y_range=yrange,
                      x_axis_type="datetime",
                      plot_width = 600,
                      plot_height = 300,
                      responsive = True)

        plot.vbar(x = contributors.month_start,
                  width = 0.8*2.62974383e9,
                  bottom = 0,
                  top = contributors.unique_commenter_count,
                  legend="Issue Commenters",
                  color="#337ab7",
                  alpha=0.8)

        plot.vbar(x = contributors.month_start,
                  width = 0.8*2.62974383e9,
                  bottom = 0,
                  top = contributors.unique_committer_count,
                  legend="Committers",
                  fill_alpha = 0.8,
                  color="#CAB2D6",
                  alpha=0.8)

        plot = self.set_xaxis_format(plot)

        return plot