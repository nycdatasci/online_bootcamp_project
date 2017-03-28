# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy
import requests
import json
from registry_scraper.items import RegistryScraperItem


START_DATE = '10/01/2016'
END_DATE = '12/31/2016'
SERIES = 2017
FORM_BASE_URL = 'https://lcr-pjr.doleta.gov/index.cfm?event=ehLCJRExternal.dspCert&doc_id=3&visa_class_id=1&id='
EMPLOYERS = 'registry_scraper/input/employers.txt'
EMPLOYERS_EXP = 'registry_scraper/output/employers_exceptions.txt'
COUNTER = 0


def getCounts(companyName, start_date, end_date):
	'''
	get the count of ids based on company name from API
	'''
	baseURL = ('https://lcr-pjr.doleta.gov/index.cfm?event=ehLCJRExternal.doAdvCertSearchCounter'
	+ '&employer_business_name=' + companyName 
	+ '&start_date_from=' + start_date 
	+ '&start_date_to=' + end_date 
	+ '&h1b_data_series=' + str(SERIES) + '&visa_class_id=1')

	response = requests.get(baseURL).text
	return int(response)



def getIds(companyName, start_date, end_date):
	'''
	to get a list of ids based on company name from API
	'''
	ids = list()
	baseURL = ('https://lcr-pjr.doleta.gov/index.cfm?event=ehLCJRExternal.dspAdvCertSearchResultGridData'
	+ '&startSearch=1&employer_business_name=' + companyName
	+ '&start_date_from=' + start_date
	+ '&start_date_to=' + end_date
	+ '&h1b_data_series=' + str(SERIES)
	+ '&visa_class_id=1&page=1&rows=1000&sidx=create_date&sord=desc')

	response = requests.get(baseURL).text
	idCount = getCounts(companyName, start_date, end_date)

	if idCount > 1000:
		ids = getIdsByMonth(companyName, start_date, end_date) 
	elif response.find("An Exception Occurred") >= 0:
		text_file = open(EMPLOYERS_EXP, "wb")
		text_file.write(companyName + '\n')
		text_file.close()
		print("Request failed")
	else:
		result = json.loads(response)
		for row in result['ROWS']:
			ids.append(row[0])
	
	return ids

def getIdsByMonth(companyName, start_date, end_date):

	start_list = start_date.split('/')
	end_list = end_date.split('/')
	months = range(int(start_list[0]), int(end_list[0])+1)
	ids = list()
	for month in months:
		if (getCounts(companyName, str(month) + '/01/' + str(SERIES-1) , str(month) + '/30/' + str(SERIES-1)) <= 1000):
			ids.extend(getIds(companyName, str(month) + '/01/' + str(SERIES-1) , str(month) + '/30/' + str(SERIES-1)))
		else:
			text_file = open(EMPLOYERS_EXP, "wb")
			text_file.write(companyName + '\n')
			text_file.close()

			print('There are more than 1000 ids for ' + companyName + ' in ' + str(month) + '/01/' + str((SERIES-1)))
	return ids





class RegisterySpider(scrapy.Spider):
	name = "registry_spider"

	def start_requests(self):
		with open(EMPLOYERS, 'r') as employers:
			for employer in employers:
				employer_ids = getIds(employer, START_DATE, END_DATE)
				for each_id in employer_ids:
					url = FORM_BASE_URL + str(each_id)
					yield scrapy.Request(url=url, callback = self.parse)
				

	def parse(self, response):

		global COUNTER

		case_number = response.xpath('//*[@id="detail"]/div[14]/div[6]/p/text()').extract()
		company = response.xpath('//*[@id="detail"]/div[4]/div[2]/p/text()').extract()
		city = response.xpath('//*[@id="detail"]/div[8]/div[6]/p/text()').extract()
		county = response.xpath('//*[@id="detail"]/div[8]/div[7]/p/text()').extract()
		state = response.xpath('//*[@id="detail"]/div[8]/div[8]/p/text()').extract()
		zipcode = response.xpath('//*[@id="detail"]/div[8]/div[9]/p/text()').extract()

		item = RegistryScraperItem()
		item['case_number'] = case_number
		item['employer_name'] = company
		item['city'] = city
		item['county'] = county
		item['state'] = state
		item['zipcode'] = zipcode

		COUNTER += 1
		print COUNTER

		yield item

