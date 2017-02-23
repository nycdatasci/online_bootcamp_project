from scrapy import Spider
from scrapy.http import Request
from scrapy.selector import Selector
from GTM.items import ArticleItem

# Define spider classes to parse scraped data

class GTMspider(Spider):
	name = 'GTM.spider'
	allowed_urls = ['https://www.greentechmedia.com']
	start_urls = [
	'https://www.greentechmedia.com/articles'
	]
	#'https://www.greentechmedia.com/articles/P25',
	#'https://www.greentechmedia.com/articles/P50',
	#'https://www.greentechmedia.com/articles/P75'
	

	# Parse title pages with 25 articles each, direct spider to each article page
	def parse(self, response):
		# List of links
		articles = response.xpath('//div[@class="article-wrapper"]/a/@href').extract()[0:5]
		# For each article link make a request to that page to be parsed using article parser
		for link in articles:
			yield Request(response.urljoin(link),callback = self.parseArticle)

	def parseArticle(self, response):
		# Define methods to parse article information
		theme = response.xpath('//div[@class="article-header-box"]/strong/text()').extract_first()
		title = response.xpath('//h1[@class="article-page-heading"]/text()').extract_first()
		pubDate = response.xpath('//span[@class="by-info"]/text()').extract_first()
		#body
		tags = response.xpath('//ul[@class="tag-list"]/li/a/text()').extract()
		comments = response.xpath('//span[@class="comment-count"]/a/text()').extract_first()

		# Create item for output to pipeline
		item = ArticleItem()
		item['theme'] = theme
		item['title'] = title
		item['pubDate'] = pubDate
		#item['body'] = body
		item['tags'] = tags
		item['comments'] = comments

		yield item



