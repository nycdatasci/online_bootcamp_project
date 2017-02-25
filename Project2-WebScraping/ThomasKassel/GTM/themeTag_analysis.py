# This script summarizes the scraped data from greentechmedia.com
# by collecting counts of articles by theme and tag, saving as dataframes for dataVis with R

import json
import pandas as pd

# Open scraped data file - each line is an article stored in a JSON object
# With 'json' package, each object is converted to a dictionary
with open('GTM_output.json','r') as json_file:

# Loop through articles, collecting metadata on article counts
	themeCount = {}
	tagCount = {}

	for line in json_file:
		article = json.loads(line)
		
		# By article theme - total # of articles, total # of comments
		articleTheme = str(article['theme'])
		articleComments = int(str(article['comments']))
		if themeCount.has_key(articleTheme):
			themeCount[articleTheme] = [themeCount[articleTheme] + 1 , themeCount[articleTheme] + articleComments]
		else:
			themeCount[articleTheme] = [1 , articleComments]

		# By tags - total # of articles, total # of comments
		articleTags = article['tags']
		articleTags = map(str,articleTags)
		for tag in articleTags:
			if tagCount.has_key(tag):
				tagCount[tag] = [tagCount[tag] + 1 , tagCount[tag] + articleComments]
			else:
				tagCount[tag] = [1 , articleComments]

	themesdf = pd.DataFrame()
	themesdf['theme'] = themeCount.keys()
	themesdf['numArticles'] = map(lambda x : x[0],themeCount.values())
	themesdf['numComments'] = map(lambda x : x[1],themeCount.values())

	tagsdf = pd.DataFrame()
	tagsdf['theme'] = tagCount.keys()
	tagsdf['numArticles'] = map(lambda x : x[0],tagCount.values())
	tagsdf['numComments'] = map(lambda x : x[1],tagCount.values())
	
	print themesdf
	print tagsdf
	