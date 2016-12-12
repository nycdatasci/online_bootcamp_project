# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

import scrapy


class FlairsItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    comments = scrapy.Field()
    link = scrapy.Field()
    title = scrapy.Field()
    score = scrapy.Field()
    flair_map = scrapy.Field()
