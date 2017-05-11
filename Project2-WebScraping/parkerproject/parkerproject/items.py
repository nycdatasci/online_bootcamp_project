import scrapy
from scrapy import Item, Field

class MovieListItem(Item):
	name = Field()
	link = Field()
	date = Field()
	