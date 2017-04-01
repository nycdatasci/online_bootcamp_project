# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

from scrapy import Item, Field


class NBA_Item(Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    Rank = Field()
    Team = Field()
    Current_Yr_Off = Field()
    Last_3 = Field()
    Last_1 = Field()
    Home = Field()
    Away = Field()
    Last_Yr_Off = Field()
