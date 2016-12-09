import scrapy
import datetime as dt
import unicodedata
import pandas

#The goal is to collect posts from r/soccer for last 100 days ago with words
#(scores or goal) and (vs or against) in them 

class RSoccerSpider(scrapy.Spider):
    name = "rsoccer"

    start_urls = ['http://www.reddit.com/r/soccer']
    counter = 1

    def parse(self,response):
        print("Visited %s",response.url)
        self.counter += 1
        print("Counter =",str(self.counter))

        if(self.counter > 5):
            return

        next_page = response.css('.next-button a::attr(href)').extract_first()
        print(next_page)

        if next_page is not None:
            yield scrapy.Request(response.urljoin(next_page), self.parse)        
        
