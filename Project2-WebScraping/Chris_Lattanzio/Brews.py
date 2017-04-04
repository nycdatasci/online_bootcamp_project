from selenium import webdriver
from selenium.webdriver.support.ui import Select
from bs4 import BeautifulSoup
import re
import requests
import pandas as pd


driver = webdriver.Chrome()
driver.get('https://www.brewersassociation.org/directories/breweries/')

driver.refresh()

div = driver.find_element_by_id('country')
div.click() 

option = div.find_element_by_xpath('./ul/li[. = "United States"]')
option.click()

driver.implicitly_wait(10)

e = driver.find_elements_by_css_selector('.brewery')

brews = []
for i in range(7249):
    new = e[i].text
    brews.append(new)

print(brews)
#content = driver.find_element_by_css_selector('.brewery .name')
#print(content)

#rows_data = pd.DataFrame(columns=['Brewery', 'Address'])
#brewery = driver.find_elements_by_class_name('brewery')
#name = driver.find_elements_by_class_name('name')
#address = driver.find_elements_by_class_name('address')

#rows_data.append([name,address])



#rows_data.head()


