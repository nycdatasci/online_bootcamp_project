from github import Github
from Repo import Repo
from WebPage import WebPage
from os import chdir, getcwd
from os.path import expanduser
import sys
import time # for timing execution only
from bokeh.embed import components

time_start = time.time()

def get_github(credentials_filename = 'github_credentials.txt'):
    with open(credentials_filename) as f:
        credentials = [ x.strip() for x in f.readlines()]
    return Github(credentials[0],credentials[1])

def get_repo(github, repo_author, repo_name):
    repo = None
    try:
        raw_repo = github.get_repo(repo_author + '/' + repo_name)
        repo = Repo(raw_repo)
    except Exception as exc:
        print "Unable to find repository", exc
        sys.exit()
    return repo

def prepare_environment():
    # change encoding to Unicode
    reload(sys)
    sys.setdefaultencoding('utf8')
    # change to home directory
    chdir(expanduser('~'))

prepare_environment()

try:
    credentials_filename = sys.argv[1]
    print "credentials_filename:", credentials_filename
except Exception as exc:
    print "Credentials filename not provided", exc
    sys.exit()

github = get_github(credentials_filename)
print github.get_rate_limit()

try:
    repo_author = str(sys.argv[2])
    repo_name = str(sys.argv[3])
except Exception as exc:
    print "Repository information not provided", exc
    sys.exit()

repo = get_repo(github, repo_author, repo_name)

print github.get_rate_limit()

time_end = time.time()
time_elapsed = time_end - time_start
print time_elapsed


plots = {'commit_timeseries': repo.get_commit_timeseries(),
         'comment_polarity_timeseries': repo.get_comment_timeseries(),
         'unique_contributors': repo.get_unique_contributor_barchart()}

script, div = components(plots)

page = WebPage(script)

page.set_part("{Name}", repo.get_full_name())
page.set_part("{Description}", repo.get_description())
page.set_part("{title-name}", repo.get_full_name())
page.set_part("{url}", repo.get_url())

page.set_part("{A1}", repo.get_summary_information())
page.set_part("{A2}", div['unique_contributors'])
page.set_part("{A3}", repo.get_text_statistics())

page.set_part("{B1}", repo.get_maintenance_statistics())
page.set_part("{B2}", div['commit_timeseries'])
page.set_part("{B3}", div['comment_polarity_timeseries'])

page.set_part("{C1}", repo.get_text_key_phrases())
page.set_part("{C2}", "")

page.show()

