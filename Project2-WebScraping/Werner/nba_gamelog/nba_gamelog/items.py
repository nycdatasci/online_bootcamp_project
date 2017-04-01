# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

from scrapy import Item, Field


class NBA_Item(Item):
    # define the fields for your item here like:
    
    player = Field()
    pos = Field()
    _min = Field()
    FGM_A = Field()
    _3PM_A = Field()
    FTM_A = Field()
    plus_minus = Field()
    OFF = Field()
    DEF = Field()
    TOT = Field()
    AST = Field()
    PF = Field()
    ST = Field()
    TO = Field()
    BS = Field()
    BA = Field()
    PTS = Field()
