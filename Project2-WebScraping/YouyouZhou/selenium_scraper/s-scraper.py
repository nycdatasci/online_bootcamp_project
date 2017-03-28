from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
import json

employers = list()
with open('remaining_employers.txt') as file:
	for line in file:
		employers.append(line)

dates = ['10/01/2016','12/31/2016']

# start driver

driver = webdriver.Chrome()
driver.get("https://lcr-pjr.doleta.gov/index.cfm?event=ehLCJRExternal.dspAdvCertSearch")
assert "PLC Version 2 Custom" in driver.title
		


def getCounts(employer):

	'''
	takes the company name and returns the number of 
	applications submitted during the period between 
	the first and second elements of the dates obj
	'''
	global driver

	if (len(driver.find_elements_by_css_selector('#visa_h1b1'))==0):
		driver.back()

	driver.implicitly_wait(3)

	driver.find_element_by_id("visa_h1b1").click()
	elem1 = driver.find_element_by_id('employer_business_name')
	elem1.clear()
	elem1.send_keys(employer)

	elem2 = driver.find_element_by_id('start_date_from')
	elem2.clear()
	elem2.send_keys(dates[0])

	elem3 = driver.find_element_by_id('start_date_to')
	elem3.clear()
	elem3.send_keys(dates[1])

	driver.find_element_by_id('btnSearch_employment2').click()

	elem = driver.find_element_by_id('numberOfCaseFound')
	wait = WebDriverWait(driver, 5)
	count = wait.until(EC.visibility_of(elem)).text

	return int(count.replace(',',''))


def getIds(employer):
	'''
	take company name, initial list of ids and append new ids of applications
	from the result table page to the initial list of ids
	'''
	global dates, driver
	ids = []


	if (getCounts(employer) <= 1000):
		# hit the result button, proceed to the result page, and get a list of ids
		# if there are paginations, go through each page and append to the list of ids
		driver.find_element_by_id('btnShowResult').click()

		wait = WebDriverWait(driver, 20)
		caseIDs = wait.until(EC.presence_of_all_elements_located((By.XPATH, '//*[@id="fakeHeader"]/tr/td[13]/a')))
		for each in caseIDs:
			ids.append(each.get_attribute('href').split('=')[4])
		dates.pop(0)
		dates.pop(0)

	else:
		dates = splitByMonth()

		while len(dates) >= 2:
			ids.extend(getIds(employer))

	return ids


def splitByMonth():
	'''
	two possibilities, by month or by date
	'''
	global dates

	start_list = dates[0].split('/')
	end_list = dates[1].split('/')
	output = []

	if (int(end_list[0]) - int(start_list[0]) > 1):
		months = range(int(start_list[0]), int(end_list[0])+1)
		for month in months:
			output.append(str(month) + '/01/' + start_list[2])
			output.append(str(month) + '/' + getLastDate(month, start_list[2]) + '/' + start_list[2])
	else:
		one_third = int(int(end_list[1])/3+1)
		two_thirds = int(int(end_list[1])*2/3+1)

		current_month = start_list[0]
		current_year = start_list[2]
		# first date entry
		output.append(dates[0])
		output.append(current_month + '/' + str(one_third) + '/' + current_year)
		# second date entry
		output.append(current_month + '/' + str(one_third + 1) + '/' + current_year)
		output.append(current_month + '/' + str(two_thirds) + '/' + current_year)
		# third date entry
		output.append(current_month + '/' + str(two_thirds + 1) + '/' + current_year)
		output.append(dates[1])

	dates.pop(0)
	dates.pop(0)
	output.extend(dates)

	return output


def getLastDate(month, year):
	if (int(month) in [1,3,5,7,8,10,12]):
		return '31'
	elif(int(month) == 2):
		if (int(year)%4 == 0):
			return '29'
		else:
			return '28'
	else:
		return '30'



def iterateEmployers(employers):
	global dates
	empObj = list()

	for employer in employers:
		dt = dict()
		dt['ids'] = getIds(employer)
		dt['name'] = employer
		empObj.append(dt)
		dates = ['10/01/2016','12/31/2016']

	driver.close()

	with open('data.txt', 'w') as outfile:
		json.dump(empObj, outfile)




iterateEmployers(employers)




