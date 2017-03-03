from scrapy import Spider
from scrapy.spiders import CrawlSpider , Rule
from scrapy.linkextractors import LinkExtractor
from scrapy.http import Request
from scrapy.selector import Selector
from cleantechScrapy.items import GTMArticleItem
from cleantechScrapy.items import Cleantech100Item


##### Crawl Spider to scrape GTM articles #####
class GTMspider(CrawlSpider):
	name = 'GTM.spider'
	allowed_urls = ['https://www.greentechmedia.com']
	start_urls = [
	'https://www.greentechmedia.com/articles',
	'https://www.greentechmedia.com/articles/P25',
	'https://www.greentechmedia.com/articles/P50'
	]

	rules = (
		# Follow links to articles and use parseArticle method at each article page
		Rule(LinkExtractor(allow=('/articles/read/.*', )), callback='parseArticle'),
		)

	def parseArticle(self, response):
		self.logger.info('Successfully crawled to %s', response.url)
		
		# Initialize article item
		item = GTMArticleItem()
		
		# Parse article information using xpaths
		item['theme'] = response.xpath('//div[@class="article-header-box"]/strong/text()').extract_first()
		title = response.xpath('//h1[@class="article-page-heading"]/text()').extract_first()
		title = title.encode('ascii','ignore')
		item['title'] = title.strip()
		body = response.xpath('//div[@class="col-md-9"]/p/descendant-or-self::text()').extract()
		body = map(lambda x : x.encode('ascii','ignore'),body)
		body = map(lambda x : x.replace('\t',"").replace('\n'," ").replace("\\'","'"),body)
		item['body'] = ''.join(body)
		item['tags'] = response.xpath('//ul[@class="tag-list"]/li/a/text()').extract()
		item['comments'] = response.xpath('//span[@class="comment-count"]/a/text()').extract_first()

		yield item



##### Spider to scrape Cleantech 100 companies #####
class Cleantech100Spider(Spider):
	
	name = 'Cleantech100.spider'
	allowed_urls = ['https://i3connect.com/']
	start_urls = ['https://i3connect.com/gct100/the-list']

	def parse(self,response):
		# Table of 100 companies
		CompaniesTable = response.xpath('//tbody/tr').extract()
		
		# Loop through table and create item for each row/company
		for row in CompaniesTable:
			item = Cleantech100Item()

			# Parse company information using xpaths
			name = Selector(text=row).response.xpath('//tr/td[1]/a/@href').extract_first()
			item['name'] = str(name).split('/')[2].replace('-',' ')
			item['country'] = str(Selector(text=row).response.xpath('//tr/td[2]/span/text()').extract_first())
			item['funding'] = str(Selector(text=row).response.xpath('//tr/td[3]/span/text()').extract_first())
			item['sector'] = str(Selector(text=row).response.xpath('//tr/td[4]/span/text()').extract_first())
			item['startyear'] = str(Selector(text=row).response.xpath('//tr/td[5]/span/text()').extract_first())

			yield item
		

