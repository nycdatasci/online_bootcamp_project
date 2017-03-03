from scrapy import Item , Field

# Define fields for scraped articles from GTM website
class GTMArticleItem(Item):
	theme = Field()
	title = Field()
	body = Field()
	tags = Field()
	comments = Field()
		
# Define fields for scraped companies from Cleantech 100 website
class Cleantech100Item(Item):
	name = Field()
	country = Field()
	funding = Field()
	sector = Field()
	startyear = Field()
