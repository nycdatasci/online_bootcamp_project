from github import Github
from Repo import Repo
from WebPage import WebPage
from os import chdir, getcwd
from os.path import expanduser
import sys
import time # for timing execution only
from bokeh.embed import components

"""
Uses GitHub API credentials stored in a file
along with arguments (filename with the
credentials, a GitHub repository creator's
username, and repository name to access
information about a repository, perform
calculations, and display a web page profile.

The profile of the GitHub repository provides
indicators of the levels of activity, participation,
and maintenance over time as well as information
about the readability of the documentation.
"""

# Set the start time so that the time required
# to generate the profile page can be calculated.
time_start = time.time()

def get_github(credentials_filename = 'github_credentials.txt'):
    """Return a connection to Github API
    based on the credentials provided in
    the credentials_filename.
    """
    with open(credentials_filename) as f:
        credentials = [ x.strip() for x in f.readlines()]
    return Github(credentials[0],credentials[1])

def get_repo(github, repo_author, repo_name):
    """Return a repository (repo) object.

    Arguments:
    github: connection to GitHub API
    repo_author: name of repository creator
    repo_name: name of repository
    """
    repo = None
    try:
        raw_repo = github.get_repo(repo_author + '/' + repo_name)
        repo = Repo(raw_repo)
    except Exception as exc:
        print "Unable to find repository", exc
        sys.exit()
    return repo

def prepare_environment():
    """Set to Unicode and change to home directory."""
    # change encoding to Unicode
    reload(sys)
    sys.setdefaultencoding('utf8')
    # change to home directory
    chdir(expanduser('~'))

prepare_environment()

# Verify that program was called with credentials_filename.
try:
    credentials_filename = sys.argv[1]
    print "credentials_filename:", credentials_filename
except Exception as exc:
    # Exit if no filename was provided
    print "Credentials filename not provided", exc
    sys.exit()

# Create GitHub API connection
github = get_github(credentials_filename)

# Display GitHub rate remaining and limit
print github.get_rate_limit()

# Verify that repository author and name were provided.
try:
    repo_author = str(sys.argv[2])
    repo_name = str(sys.argv[3])
except Exception as exc:
    # Exit if the information is missing.
    print "Repository information not provided", exc
    sys.exit()

# Get the repository information using GitHub API.
repo = get_repo(github, repo_author, repo_name)

# Display GitHub rate remaining and limit to show usage.
print github.get_rate_limit()

# Create graphs.
plots = {'commit_timeseries': repo.get_commit_timeseries(),
         'comment_polarity_timeseries': repo.get_comment_timeseries(),
         'unique_contributors': repo.get_unique_contributor_barchart()}

# Create the separate JavaScript and HTML code to show graphs.
script, div = components(plots)

# Create a web page from a template and insert the JavaScript for graphs.
page = WebPage(script)

# Insert the repository name, description, and url in the web page.
page.set_part("{Name}", repo.get_full_name())
page.set_part("{Description}", repo.get_description())
page.set_part("{title-name}", repo.get_full_name())
page.set_part("{url}", repo.get_url())

# Insert the summary information, contributor graph, and text analysis.
page.set_part("{A1}", repo.get_summary_information())
page.set_part("{A2}", div['unique_contributors'])
page.set_part("{A3}", repo.get_text_statistics())

# Insert the maintenance metrics and graphs of commits and comment polarity.
page.set_part("{B1}", repo.get_maintenance_statistics())
page.set_part("{B2}", div['commit_timeseries'])
page.set_part("{B3}", div['comment_polarity_timeseries'])

# Insert the key text phrases and hide the remaining area of template.
page.set_part("{C1}", repo.get_text_key_phrases())
page.set_part("{C2}", "")
page.set_part("{C3}", "")

# Calculate and display time elapsed.
time_end = time.time()
time_elapsed = time_end - time_start
print "%.1f seconds elapsed while acquiring data, performing calculations, and generating graphs." % round(time_elapsed,1)

# Display web page in browser.
page.show()

