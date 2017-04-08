# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class carmaxItem(scrapy.Item):
# define the fields for your item here like:
	location = scrapy.Field()
	type = scrapy.Field()
	year = scrapy.Field()
	make = scrapy.Field()
	model = scrapy.Field()
	mileage = scrapy.Field()
	price = scrapy.Field()
	mpg_highway = scrapy.Field()
	mpg_city = scrapy.Field()
	feature_list = scrapy.Field()
	stock_number = scrapy.Field()
