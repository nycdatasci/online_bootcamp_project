from textblob import TextBlob
from textstat.textstat import textstat
import requests
from bs4 import BeautifulSoup
from markdown import markdown
import pandas as pd
import datetime
from bokeh.plotting import figure
from bokeh.models import Range1d, DatetimeTickFormatter

class Repo:

    """
    Creates a Repo (GitHub repository) object that provides
    information about a repository that comes from the GitHub
    API as well as information scraped from web pages on GitHub
    and IsItMaintained.com.

    Information returned by selected get_ functions includes
    charts and formatted text that can be displayed on a web page.
    """

    def __init__(self, raw_repo):
        """Initialize Repo object from repository information
        provided by GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        self.repo = self.set_metrics(raw_repo)

    def set_readme(self, raw_repo):
        """Set the readme text from repository information
        provided by GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        readme_content = None
        try:
            #attempt to set the readme_content as the text of
            #readme provided by repository from the GitHub API.
            readme = raw_repo.get_readme()
            if readme:
                readme_content = readme.decoded_content
                readme_html = markdown(readme_content)
                #extract the text
                readme_content = ''.join(BeautifulSoup(readme_html, 'lxml').findAll(text = True))
        except Exception as exc:
            print "Unable to get readme file from GitHub repository."
            pass

        self.readme = readme_content

    def set_commits(self, raw_repo):
        """Set a list of commit messages and a set of committer IDs
        from repository information provided by GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        self.commit_messages = []
        self.committers = set() # store unique committers
        try:
            commits = raw_repo.get_commits()
            for commit in commits:
                self.committers.add(commit.committer.id)
                self.commit_messages.append('"'+commit.commit.message+'"')
        except:
            print "Unable to set commit messages and committer IDs."
            pass
        
    def set_commit_dataframe(self, raw_repo):
        """Set a dataframe consisting of information about commits made
        by contributors (not by GitHub's web-flow bot) based on the
        repository information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
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

        self.commit_dataframe = pd.DataFrame(commit_nested_list,
                                            columns=['commit_datetime', 'commit_message', 'committer_login', 'committer_id'])

        #reorder by commit timestamp
        self.commit_dataframe.sort_values(by = 'commit_datetime', ascending = True, inplace = True)
        self.commit_dataframe.index = range(1, len(self.commit_dataframe) + 1)

    def set_contributors(self, raw_repo):
        """Populate a set with unique contributor based on the
        repository information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        self.contributor_set = set()
        contributors = raw_repo.get_contributors()

        for contributor in contributors:
            self.contributor_set.add(contributor.id)

    def set_pull_request_commenters(self, raw_repo):
        """Populate a set of commenters on pull requests
        based on the information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        self.pull_request_commenter_set = set()
        try:
            pull_request_comments = raw_repo.get_pulls_comments()
            for pull_request_comment in pull_request_comments:
                self.pull_request_commenter_set.add(pull_request_comment.user.id)
        except:
            print "Unable to obtain comments on pull requests"
            pass

    def set_issue_comment_dataframe(self, raw_repo):
        """Populate a dataframe of comment on issues
        based on the information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        comment_nested_list = []  # nested list of commits for this repo
        self.issue_comment_dataframe = None
        try:
            issue_comments = raw_repo.get_issues_comments()
            for issue_comment in issue_comments:
                # exclude comments made automatically by GitHub's web-flow bot'
                if issue_comment.user.login != 'web-flow':
                    current_comment = [ issue_comment.created_at, issue_comment.id,
                                        issue_comment.body, issue_comment.user.login,
                                        issue_comment.user.id ]
                    comment_nested_list.append(current_comment)

            self.issue_comment_dataframe = pd.DataFrame(comment_nested_list,
                                                        columns=['comment_datetime', 'comment_id', 'comment_text',
                                                                 'commenter_login', 'commenter_id'])

            # reorder by comment timestamp
            self.issue_comment_dataframe.sort_values(by='comment_datetime', ascending=True, inplace=True)
            self.issue_comment_dataframe.index = range(1, len(self.issue_comment_dataframe) + 1)
        except:
            print "Unable to obtain comments on issues"
            pass

    def set_issue_commenters(self, raw_repo):
        """Populate a set of commenters on pull requests
        based on the information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        self.issue_commenter_set = set()
        issue_comments = raw_repo.get_issues_comments()
        for issue_comment in issue_comments:
            self.issue_commenter_set.add(issue_comment.user.id)

    def set_unique_contributors(self, raw_repo):
        """Populate a set of unique contributors."""
        self.unique_contributors = self.committers | self.contributor_set | self.pull_request_commenter_set | self.issue_commenter_set

    def set_maintenance_metrics(self, raw_repo):
        """Scrape the isitmaintained.com website and store the
         median resolution time and percent open issues values
         displayed there for the selected repository.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        print raw_repo.full_name
        try:
            # access the isitmaintained.com page for the repository
            result = requests.get("http://isitmaintained.com/project/"+raw_repo.full_name)
            if result.status_code == 200:
                content = result.content
                soup = BeautifulSoup(content, 'lxml')
                i = 0
                # set the median resolution time and percent open issues
                # based on values found on the web page
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
        """Store a comma-separated string of topics obtained by
        scraping the GitHub repository's home page.
        """
        self.topics = "No topics found"
        try:
            # Get the content of the GitHub repository's home page
            result = requests.get(self.url)
            print self.url
            print result
            if result.status_code == 200:
                print "result code was 200"
                content = result.content
                soup = BeautifulSoup(content, 'lxml')
                # Find the div that holds the topics
                topics_div = soup.find("div", "list-topics-container")
                # Get the text of each topic to store
                topics_div.find_all("a")[0].contents[0].strip()
                topic_list = [topic.contents[0].strip() for topic in topics_div.find_all("a")]
                self.topics = ", ".join(topic_list)
            else:
                print "GitHub repository home page not found"
        except:
            print "Unable to get topic list"

    def set_metrics(self, raw_repo):
        """Call methods to populate a selection of fields
        based on the information provided by the GitHub API.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
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
        """For the Bokeh plot provided, set the x axis
        labels to use an abbreviated month name and year.

        raw_repo: object consisting of repository information
        from the GitHub API
        """
        plot.xaxis.formatter = DatetimeTickFormatter(#formats = dict(
            hours = ["%b %Y"],
            days = ["%b %Y"],
            months = ["%b %Y"],
            years = ["%b %Y"])
        #))
        return plot


    def get_name(self):
        """Returns short name of repository."""
        return self.name

    def get_full_name(self):
        """Returns full name of repository."""
        return self.full_name

    def get_url(self):
        """Returns url for repository's GitHub home page."""
        return self.url

    def get_created_at(self):
        """Returns creation date of repository."""
        return self.created_at

    def get_description(self):
        """Returns description of repository."""
        return self.description

    def get_readme(self):
        """Returns text content of the repository's readme."""
        return self.readme

    def get_stargazers_count(self):
        """Returns number of people who gave repository a star on GitHub."""
        return self.stargazers_count

    def get_commit_messages(self):
        """Returns a list of the repository's commit messages."""
        return self.commit_messages

    def get_committer_count(self):
        """Returns number of unique committers."""
        return len(self.committers)

    def get_commit_count(self):
        """Returns number of commits."""
        return len(self.commit_messages)

    def get_contributors(self):
        """Returns set of contributors."""
        return self.contributor_set

    def get_contributor_count(self):
        """Returns number of unique contributors."""
        return len(self.contributor_set)

    def get_pull_request_commenter_count(self):
        """Returns number of commenters on pull requests."""
        return len(self.pull_request_commenter_set)

    def get_issue_commenter_count(self):
        """Returns number of commenters on issues."""
        return len(self.issue_commenter_set)
    
    def get_description_polarity(self):
        """Calculates and returns polarity of description using
        TextBlob with 1 for positive and -1 for negative.
        """
        if self.description:
            return TextBlob(self.description).polarity
        else:
            return None

    def get_description_subjectivity(self):
        """Calculates and returns subjectivity of description using
        TextBlob with 0 for highly objective and 1 for highly subjective.
        """
        if self.description:
            return TextBlob(self.description).subjectivity
        else:
            return None

    def get_description_flesch_reading_ease(self):
        """Calculates the Flesch Reading Ease level of the
        repository's description, with 100 being easiest to
        read and 0 being hardest, using textstat.
        """
        if self.description:
            return textstat.flesch_reading_ease(self.description)
        else:
            return None

    def get_description_composite_grade_level(self):
        """Calculates the grade level of the repository's
        description using a variety of measures in textstat.
        """
        if self.description:
            return textstat.text_standard(self.description)
        else:
            return None

    def get_description_noun_phrases(self):
        """Get the noun phrases detected by TextBlob in
        the repository's description.
        """
        if self.description:
            return TextBlob(self.description).noun_phrases
        else:
            return None

    def get_readme_polarity(self):
        """Calculates and returns polarity of readme using
        TextBlob with 1 for positive and -1 for negative.
        """
        if self.readme:
            return TextBlob(self.readme).polarity
        else:
            return None

    def get_readme_subjectivity(self):
        """Calculates and returns subjectivity of readme using
        TextBlob with 0 for highly objective and 1 for highly subjective.
        """
        if self.readme:
            return TextBlob(self.readme).subjectivity
        else:
            return None

    def get_readme_flesch_reading_ease(self):
        """Calculates the Flesch Reading Ease level of the
        repository's readme, with 100 being easiest to
        read and 0 being hardest, using textstat.
        """
        if self.readme:
            return textstat.flesch_reading_ease(self.readme)
        else:
            return None

    def get_readme_composite_grade_level(self):
        """Calculates the grade level of the repository's
        readme using a variety of measures in textstat.
        """
        if self.readme:
            return textstat.text_standard(self.readme)
        else:
            return None

    def get_readme_noun_phrases(self):
        """Get a list of the noun phrases detected by TextBlob in
        the repository's readme.
        """
        if self.readme:
            return list(set(TextBlob(self.readme).noun_phrases))
        else:
            return None

    def get_median_resolution_time(self):
        """Returns the median resolution time of the repository."""
        return self.median_resolution_time

    def get_percent_open_issues(self):
        """Returns the percent of open issues of the repository."""
        return self.percent_open_issues

    def get_language(self):
        """Returns the programming language of the repository."""
        return self.language

    def get_topics(self):
        """Returns a comma-separated string of topics for the
        repository.
        """
        return self.topics

    def get_commit_timeseries(self):
        """Generates and returns a Bokeh bar chart of the monthly
        number of commits of the repository.
        """
        # Resample the dataframe of commits using the month start (MS) option.
        monthly_commit_count = self.commit_dataframe.set_index('commit_datetime').resample('MS').size()

        # Define the x range as being from the month of the first commit to the first of the month
        # after the current month
        start_date = datetime.datetime.utcfromtimestamp(monthly_commit_count.index.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1,1))

        # Set the y range as being from 0 to 20 percent higher than the maximum y value.
        max_y = monthly_commit_count.values.max()

        yrange = Range1d(start=0, end=max_y * 1.2)

        # Define the plot size, title, labels, and ranges.
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

        # Add vertical bars for commit counts.
        plot.vbar(x = monthly_commit_count.index,
                  width = 0.8*2.62974383e9,# 80 percent of the width of a month in milliseconds
                  bottom = 0,
                  top = monthly_commit_count.values,
                  color="#337ab7")

        # format the labels on the x axis
        plot = self.set_xaxis_format(plot)

        return plot

    def get_comment_timeseries(self):
        """Generates and returns a Bokeh bar chart of the monthly
        number of commits of the repository.
        """

        # Start with the dataframe of comments on issues for the repository
        issue_comment_df = self.issue_comment_dataframe

        # Make the date and time for the comments the index
        issue_comment_df.set_index('comment_datetime', inplace = True)

        # Calculate and store the polarity (measure of positivity or negativity) of somments
        issue_comment_df['polarity'] = issue_comment_df['comment_text'].apply(lambda x: TextBlob(x).polarity)

        # Define the x range as being from the date of the first comment to the current date
        start_date = pd.Timestamp(min(issue_comment_df.index.values)).to_datetime()

        today = datetime.date.today()

        xrange = Range1d(start=datetime.date(start_date.year, start_date.month, start_date.day),
                         end=datetime.date(today.year, today.month, today.day))

        # Define the y range as -1 (highly negative) to 1 (highly positive).
        yrange = Range1d(start = -1, end = 1)

        # Define the plot size, title, labels, and ranges.
        TOOLS = "pan,wheel_zoom,box_zoom,reset,save"
        plot = figure(title="Issue Comment Polarity", x_axis_label="Date", y_axis_label="Polarity",
                      x_range=xrange, x_axis_type="datetime",
                      y_range = yrange,
                      tools=TOOLS, plot_width=600, plot_height=300, responsive=True)

        # Add vertical bars for comment polarity.
        plot.line(  x=issue_comment_df.index,
                    y=issue_comment_df.polarity,
                    line_width = 2,
                    color="#337ab7",
                    alpha = 0.5)

        # format the labels on the x axis
        plot = self.set_xaxis_format(plot)

        return plot

    def get_text_statistics(self):
        """Returns an html div that can be displayed on a web page
        to show indicators of the level of readability of the
        description and readme of a GitHub repository.
        """
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
        """Returns an html div that can be displayed on a web page
        to show indicators of the level of maintenance of a GitHub repository.
        """
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
        """Returns an html div that can be displayed on a web page to show
        the programming language, topics, and star count of a GitHub repository.
        """
        html = '''<div class="list-group">
                 <a href="#" class="list-group-item active">Summary Information</a>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{0}</span>Language
                </div>
                <div class="list-group-item" style="text-indent: 1em;">
                    <span class="badge" style="text-indent: 0;">{1}</span>Topics
                </div>
                <a class="list-group-item active"><span class="badge">{2}</span>Star Count</a>
            </div>'''.format(str("%s" % self.get_language()),
                             str("%s" % self.get_topics()),
                             str("%s" % self.get_stargazers_count()))
        return html

    def get_text_key_phrases(self):
        """Returns an html div that can be displayed on a web page
        to show the noun phrases found in the description and readme
        of a GitHub repository.
        """
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
        """Returns a dataframe with the start dates of each month since the first commit
        of the GitHub repository and the number of unique users who committed each month.
        """
        # Start with the dataframe of commits.
        commits = self.commit_dataframe
        # Calculate and set the month start of commits in the dataframe.
        commits['month_start'] = commits.commit_datetime.apply(lambda x: datetime.datetime(x.date().year, x.date().month, 1))

        # drop unneeded columns
        commits.drop('commit_message', axis = 1, inplace = True)
        commits.drop('committer_login', axis = 1, inplace = True)
        commits.drop('commit_datetime', axis = 1, inplace = True)
        unique_committer_by_month = commits.groupby('month_start').agg({"committer_id": lambda x: x.nunique()})
        # rename column
        unique_committer_by_month = unique_committer_by_month.rename(columns = {'committer_id': 'unique_committer_count'})
        unique_committer_by_month.reset_index(inplace = True)

        return unique_committer_by_month


    def get_unique_issue_commenter_by_month(self):
        """Returns a dataframe with the start dates of each month since the first comment on an
        issue for the GitHub repository and the number of unique users who commented on an issue
        each month.
        """
        # Start with the dataframe of comments on issues.
        comments = self.issue_comment_dataframe
        # Resample the dataframe of comments on issues using the month start (MS) option.
        comments['month_start'] = comments.index.to_series().apply(lambda x: datetime.datetime(x.year, x.month, 1))

        # Drop unneeded columns
        comments.drop('comment_id', axis = 1, inplace = True)
        comments.drop('comment_text', axis = 1, inplace = True)
        comments.drop('commenter_login', axis = 1, inplace = True)

        # Group by month and calculate the number of unique commenters.
        unique_commenter_by_month = comments.groupby('month_start').agg({"commenter_id": lambda x: x.nunique()})

        # Rename columns and reset index.
        unique_commenter_by_month = unique_commenter_by_month.rename(columns = {'commenter_id': 'unique_commenter_count'})
        unique_commenter_by_month.reset_index(inplace = True)

        return unique_commenter_by_month

    def get_unique_committer_barchart(self):
        """Generates and returns a Bokeh bar chart of the monthly
        number of unique committers of the repository.
        """

        # Start with the dataframe of comments on issues for the repository
        unique_committer_by_month = self.get_unique_committer_by_month()

        # Define the x range as being from the month of the first commit to the first of the month
        # after the current month.
        start_date = datetime.datetime.utcfromtimestamp(unique_committer_by_month.month_start.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1, 1))

        # Define the plot size, title, labels, and ranges.
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

        # Add vertical bars for commit counts.
        plot.vbar(x = unique_committer_by_month.month_start,
                  width = 0.8*2.62974383e9,# 80 percent of the width of a month in milliseconds
                  bottom = 0,
                  top = unique_committer_by_month.unique_committer_count,
                  color="#337ab7")
                  # color="#CAB2D6")

        # format the labels on the x axis
        plot = self.set_xaxis_format(plot)

        return plot

    def get_unique_contributor_barchart(self):
        """Generates and returns a Bokeh bar chart of the monthly
        number of unique committers and commenters of the repository.
        """

        # Start with the dataframes of committers and commenters on issues for the repository
        unique_committer_by_month = self.get_unique_committer_by_month()
        unique_issue_commenter_by_month = self.get_unique_issue_commenter_by_month()

        # Merge the dataframes as an outer join
        contributors = pd.merge(unique_committer_by_month, unique_issue_commenter_by_month, on = "month_start",
                                how = "outer")

        # Replace NaN values with zeros for the number of committers or issue commenters
        contributors = contributors.fillna(0)

        # Define the x range as being from the month of the first commit to the first of the month
        # after the current month.
        start_date = datetime.datetime.utcfromtimestamp(contributors.month_start.values.tolist()[0]/1e9)

        today = datetime.date.today()

        xrange = Range1d(start = datetime.date(start_date.year, start_date.month - 1,1),
                         end = datetime.date(today.year, today.month + 1,1))

        # Set the y range as being from 0 to 20 percent higher than the maximum y value.
        max_y = contributors[['unique_committer_count','unique_commenter_count']].values.max()

        yrange = Range1d(start = 0, end = max_y*1.2)

        # Define the plot size, title, labels, and ranges.
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

        # Add vertical bars for committer and commenter counts.
        plot.vbar(x = contributors.month_start,
                  width = 0.8*2.62974383e9,# 80 percent of the width of a month in milliseconds
                  bottom = 0,
                  top = contributors.unique_commenter_count,
                  legend="Issue Commenters",
                  color="#337ab7",
                  alpha=0.8)

        plot.vbar(x = contributors.month_start,
                  width = 0.8*2.62974383e9,# 80 percent of the width of a month in milliseconds
                  bottom = 0,
                  top = contributors.unique_committer_count,
                  legend="Committers",
                  fill_alpha = 0.8,
                  color="#CAB2D6",
                  alpha=0.8)

        # format the labels on the x axis
        plot = self.set_xaxis_format(plot)

        return plot