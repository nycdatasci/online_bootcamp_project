# -*- coding: utf-8 -*-
# http://doc.scrapy.org/en/latest/topics/items.html

from scrapy import Item , Field

# Define containers for scraped items from GTM website
class ArticleItem(Item):
	theme = Field()
	title = Field()
	pubDate = Field()
	#body = Field()
	tags = Field()
	comments = Field()

