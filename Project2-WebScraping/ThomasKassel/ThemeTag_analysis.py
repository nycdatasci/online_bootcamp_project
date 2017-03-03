# This script summarizes the 'theme', 'tags', and 'comments' attributes
# of each scraped article from greentechmedia.com for further dataVis using R

import json
import pandas as pd
import numpy as np

# Open scraped data file - each line is an article stored in a JSON object
# With 'json' package, each object is converted to a dictionary
with open('scraped_data/GTMarticles.json','r') as json_file:

# Loop through articles, collecting # articles/comments for each theme and tag
	outputdf = pd.DataFrame(columns=['topic','type','numComments'])

	for line in json_file:
		# New row for each article theme
		article = json.loads(line)
		theme = str(article['theme'])
		comments = int(str(article['comments']))
		themedf = pd.DataFrame([[theme,'Theme',comments]],columns=['topic','type','numComments'])
		
		# New row for each article tag
		articleTags = article['tags']
		articleTags = map(lambda x : x.encode('ascii','ignore'), articleTags)
		tagdf = pd.DataFrame(columns=['topic','type','numComments'])
		for tag in articleTags:
			temp = pd.DataFrame([[tag,'Tag',comments]],columns=['topic','type','numComments'])
			tagdf = pd.concat([tagdf,temp],axis=0)

		outputdf = pd.concat([outputdf,themedf,tagdf],axis=0)

# Save to CSV for further visual analysis in R
outputdf.to_csv('outputs/ThemeTagOutput.csv',index=False)
	