GitHub Profiler

GitHub Profiler provides a profile of a GitHub repository that provides an indication of activity, participation,
and maintenance over time as well as information about the readability of the documentation.

It should be called with three arguments:
1. The name of the file containing GitHub credentials (see below)
2. The name of the creator of the GitHub repository
3. The name of the repository itself

Example:
__main__.py github_credentials.txt ayush1997 visualize_ML

GitHub Credentials:
Create a file called github_credentials.txt in your home directory.
Enter your GitHub username in the first line of the file and your GitHub password in the second line.

Installation Requirements:
pip install PyGithub
pip install -U textblob
python -m textblob.download_corpora
pip install textstat
pip install beautifulsoup4
pip install requests
pip install bokeh


