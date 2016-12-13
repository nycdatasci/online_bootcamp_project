import scrapy
from flairs.items import FlairsItem
import pandas as pd

class FlairSpider(scrapy.Spider):
    name = "flairs"
    Ncomments_upper = 500 #Collect flairs for top xx comments
    Ncomments_lower = 100 #Only submissions with xx comments will be analyzed
    submission_count = 0

    allowed_domains = ["reddit.com"]
    start_urls = ['https://www.reddit.com/r/soccer/top/?t=month'] #top submissions in the past week

    def parse(self,response):
        self.logger.info("Visited %s",response.url)

        for submission in response.css('.comments'):
            #Include only submissions above lower limit
            comment_parse = submission.css('a::text').extract_first().split()
            self.submission_count += 1
            self.logger.info("Submission Count = %s", str(self.submission_count))
            if len(comment_parse)==1:
                Ncomments = 0
            else:
                Ncomments = int(comment_parse[0])
            if(Ncomments >= self.Ncomments_lower):
                item = FlairsItem()
                item['comments'] = Ncomments
                comments_href = submission.css('a::attr(href)').extract_first() + "?sort=top&limit=" + str(self.Ncomments_upper) #limiting to top 300 comments in a submission
                item['link'] = response.urljoin(comments_href)
                request = scrapy.Request(response.urljoin(comments_href),callback = self.parse_submission)
                request.meta['item'] = item
                yield(request)

        next_page = response.css('.next-button a::attr(href)').extract_first()
        if next_page is not None:
            yield scrapy.Request(response.urljoin(next_page), callback = self.parse)


    def parse_submission(self, response):
        self.logger.info("Visited %s", response.url)
        item = response.meta['item']

        item['title'] = response.css('.title::text').extract()[1]
        item['score'] = response.css('.likes::text').extract_first()
        item['flair_map'] = {}

        for tagline in response.css('.tagline')[1:]: #first is submission poster
            redditor = tagline.css('a::text').extract()
            if len(redditor)==3:
                redditor = redditor[1]
                if(redditor not in list(item['flair_map'].keys())):
                    flair = tagline.css('.flair::text').extract_first()
                    if flair:
                        item['flair_map'][redditor] = flair

        yield(item)
