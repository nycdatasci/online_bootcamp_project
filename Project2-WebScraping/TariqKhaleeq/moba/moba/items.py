# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# http://doc.scrapy.org/en/latest/topics/items.html

from scrapy import Field, Item


class MobaItem(Item):
    name = Field()
    alias = Field()
    pos1 = Field()
    pickratepos1 = Field()
    winrate1 = Field()
    pos2 = Field()
    pickratepos2 = Field()
    winrate2 = Field()
    damage = Field()
    toughness = Field()
    cc = Field()
    mobility = Field()
    utility = Field() 
    pass
