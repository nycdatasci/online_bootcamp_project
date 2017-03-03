# This script conducts natural language processing on the 'body' (main text)
# of each scraped article from greentechmedia.com by analysing number of
# occurrences and sentiment of proper nouns (companies, people, countries) in cleantech

import json
import re
import numpy as np
import pandas as pd 
from textblob import TextBlob


######## Proper noun lists ########
# Cleantech 100 companies list - scraped from https://i3connect.com/gct100/the-list
with open('scraped_data/Cleantech100.json','r') as companies:
	companyNames = []
	for line in companies:
		company = json.loads(line)
		companyNames.append(company['name'])
		companyNames = map(str,companyNames)

# 'High-influence people & companies' lists - created ad hoc
BigPeople = ['Musk','Gates','Khosla','Trump','Pruitt','Tillerson']
BigCompanies = ['Tesla','SunPower','SolarCity','GE','Siemens']
Countries = ['U.S.','China','India','France','Germany','Israel','Canada','Ireland','Netherlands','U.K.']

 
######## Workhorse function to conduct NLP ########
def analyzeProperNoun(nounlist,caps=True):
	# Given a list of proper nouns (companies, people, etc), searches through all 
	# scraped GTM articles to find number of unique articles the noun was mentioned in,
	# total mentions, and average polarity/subjectivity of all sentences containing the noun

	# Initialize empty df to hold outputs
	nounsdf = pd.DataFrame(columns=['noun','uniqueMentions','totalMentions','sumPolarity','sumSubjectivity'])

	with open('scraped_data/GTMarticles.json','r') as json_file:
		# Read in scraped GTM articles line-by-line 
		for line in json_file:
			article = json.loads(line)
			body = str(article['body'])

			for NP in nounlist:
				# Total occurrences of the NP in the article
				if caps == True:
					regexNP = "[ ,/.]" + NP.title() + "[ 's,/.]"	# Regex for flexible matching
				else:
					regexNP = "[ ,/.]" + NP + "[ 's,/.]"	# Regex for flexible matching
				NPcount = len(re.findall(regexNP,body))

				if NPcount > 0:
					# Sentiment for sentences containing the NP
					Allsentences = map(str,TextBlob(body).sentences)
					NPsentences = [elem for elem in Allsentences if re.search(regexNP,elem)]
					polarity = map(lambda x : x.sentiment.polarity, map(TextBlob,NPsentences))
					polarity = np.sum(polarity)
					subjectivity = map(lambda x : x.sentiment.subjectivity, map(TextBlob,NPsentences))
					subjectivity = np.sum(subjectivity)

					# If the NP has appeared in previous articles, add to running counts in master df
					if nounsdf['noun'].str.contains(NP).any():
						nounsdf.loc[nounsdf.noun==NP,'uniqueMentions'] += 1
						nounsdf.loc[nounsdf.noun==NP,'totalMentions'] += NPcount
						nounsdf.loc[nounsdf.noun==NP,'sumPolarity'] += polarity
						nounsdf.loc[nounsdf.noun==NP,'sumSubjectivity'] += subjectivity
					# If this is the first time the NP is seen, create and concat a new row
					else:
						new = pd.DataFrame([[NP, 1, NPcount, polarity, subjectivity]],columns=['noun','uniqueMentions','totalMentions','sumPolarity','sumSubjectivity'])
						nounsdf = pd.concat([nounsdf,new],axis=0)
				else:
					next

	# Sort and return
	nounsdf = nounsdf.sort_values(by='totalMentions',axis=0,ascending=False)
	return nounsdf


######## Conduct NLP on proper noun lists and save CSVs ########
# Further visual analysis conducted in R
analyzeProperNoun(companyNames,caps=True).to_csv('outputs/Cleantech100.csv',index=False)
analyzeProperNoun(BigPeople,caps=True).to_csv('outputs/BigPeople.csv',index=False)
analyzeProperNoun(BigCompanies,caps=False).to_csv('outputs/BigCompanies.csv',index=False)
analyzeProperNoun(Countries,caps=True).to_csv('outputs/Countries.csv',index=False)