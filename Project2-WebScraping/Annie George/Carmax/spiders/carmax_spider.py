
import scrapy
import json
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver import ActionChains
import time
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait


from Carmax.items import carmaxItem



class carmaxspider(scrapy.Spider):
	name = "carmax_spider"
	allowed_domains = ["carmax.com"]
	QUERY = 'virginia'
	start_urls = (
        'https://www.carmax.com/stores/states/'+QUERY,	
    )
	
	def start_requests(self):
		self.driver = webdriver.Chrome()
		self.driver.implicitly_wait(5)
		yield scrapy.Request(url=self.start_urls[0], callback=self.parse_store)
	
	def parse_store(self, response):
#self.driver.get is a must to use selenium after a call to url using scrapy
		self.driver.get(response.url) 
		self.driver.implicitly_wait(5)

#get number of stores from the title		
		count = self.driver.find_element_by_xpath('//h1[@class="store-locator--results--header"]/span').text
		count_num = count.split(' ')[0]

#get location names		
		rows = self.driver.find_elements_by_xpath('//div[@class="store-locator--result"]')
		location = []
		for row in rows:    
			row_locate = row.find_element_by_css_selector('h4.store-locator--result--name a')
			location.append(row_locate.text)
		print location
#get urls
		url=[]
		rows = self.driver.find_elements_by_xpath('//a[@class="btn--pill alt get-vehicles-by-store"]')
		for row in rows:
			url.append(row.get_attribute('href'))
		print row
# open link in a new tab\n",
 		for i in range(0, int(count_num), 1): 
#yield allows loop, self.driver.get or return will not yield same effect	
#self defines variables that can be used in all functions in class
			self.count_car = 0
			yield scrapy.Request(url = url[i], callback=self.car_type)   
#			print ('Url: ' + (url[i]) + 'Count: ' + str(self.count_car))
############################TEST##########
#		i = 1
#		while (i == 1):		
#			yield scrapy.Request(url = url[1], callback=self.car_type) 
#			self.driver.get(url[i])   
#			i = 0
			
###############################
	def car_type(self, response):
#click type
#self.driver.get is a must to use selenium after a call to url using scrapy
			self.driver.get(response.url) 	
			self.driver.implicitly_wait(5)
			action = ActionChains(self.driver)
			menu = self.driver.find_element_by_xpath('//div[contains(@data-reactid, "582")]')
			WebDriverWait(self.driver,20).until(EC.visibility_of(menu))
			action.click(menu).perform()
		
#click sedan type    
			menu1 = menu.find_element_by_xpath('//span[contains(@data-reactid, "698")]')
			WebDriverWait(self.driver,20).until(EC.visibility_of(menu1))
			menu1.click()
			
#click filter for distance search    
			action = ActionChains(self.driver)
			filter = self.driver.find_element_by_xpath('//span[@data-reactid = "33"]')
			WebDriverWait(self.driver,20).until(EC.visibility_of(filter))
			action.click(filter).perform()
			time.sleep(10)
			
#key up 8 times to get 25 miles
			self.driver.find_element_by_class_name("Select-input").send_keys(Keys.ARROW_UP + Keys.ARROW_UP \
				+ Keys.ARROW_UP + Keys.ARROW_UP + Keys.ARROW_UP + Keys.ARROW_UP + Keys.ARROW_UP + \
				Keys.ARROW_UP + Keys.ARROW_UP + Keys.TAB)
			time.sleep(10)	
			
#call function to load all pages and load sedans 
			page = self.driver.find_element_by_xpath('//a[@class="pagination--next"]')
			while page != []:
				listing = self.driver.find_elements_by_xpath('//h3[@class="vehicle-browse--result-title tablet-hidden"]/a')

				car_url=[]
				for lists in listing:
					car_url.append(lists.get_attribute('href'))
				
				for each_car in range(0, len(car_url), 1):
					yield scrapy.Request(car_url[each_car], callback=self.parse_listing_results_page)
				self.count_car = self.count_car + len(car_url)
				actions = ActionChains(self.driver)
				page = self.driver.find_element_by_xpath('//a[@class="pagination--next"]')

				if page != []:
					actions.move_to_element(page).click().perform()               
					time.sleep(5)
			
	
	def parse_listing_results_page(self, response):
		
		item = carmaxItem()
		
		vehicle =  response.xpath('//h1[@class="stock-number-page-header__car-title"]/span/text()')[0]
		item['year'] = str(vehicle.extract().split()[0])
		item['make'] = str(vehicle.extract().split()[1])
		item['type']= 'sedan'
		model = response.xpath('//h1[@class="stock-number-page-header__car-title"]/span/text()')[1]
		item['model'] = " ".join(str(model.extract()).split())
 		item['price'] = str(response.xpath('//div[@class="price-mileage--value"]/span/text()')[0].extract())
		item['location'] = str(response.xpath('//a[@class="info-bubble--link"]/text()')[0].extract())
		item['mileage']  = str(response.xpath('//div[@class="price-mileage--value"]/text()')[2].extract())
		specs = str(response.xpath('//div[@class="card--text-block-header--center"]/text()').extract()[0])
		if specs == 'N/A':
			item['mpg_city'] = 0
			item['mpg_highway'] = 0
		else:	
			item['mpg_city'] = int(response.xpath('//span[@class="mpg--value"]/text()')[0].extract())
			item['mpg_highway'] = int(response.xpath('//span[@class="mpg--value"]/text()')[1].extract())
		
		features = response.xpath('//*[@id="key-features"]/div[1]/div/ul/li/text()').extract()
		features_desc = ', '.join([str(features[i]) for i in range(0,len(features) - 1)])
		item['feature_list'] =  features_desc		
		item['stock_number'] =  int(response.xpath('//div[@class="card-grid-section--action-bar"]/span[1]/span[2]/text()').extract()[0])
		yield item
		
