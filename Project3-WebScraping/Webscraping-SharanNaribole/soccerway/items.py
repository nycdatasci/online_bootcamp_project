# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy

class SoccerwayItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    id_name = scrapy.Field()
    first_name = scrapy.Field()
    last_name = scrapy.Field()
    profile = scrapy.Field()
    goals = scrapy.Field()
    club = scrapy.Field()
    league = scrapy.Field()
