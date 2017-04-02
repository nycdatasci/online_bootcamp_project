# name: an attribute specifying a unique name to identify the spider
# start_urls: an attribute listing the URLs the spider will start from
# parse(): a method of the spider responsible for processing a Response object downloaded from the URL and returning scraped data

import sys
reload(sys)
sys.setdefaultencoding('utf-8') # Need to set default to utf-8, otherwise ascii codec will give error.
import re

from scrapy import Spider, Request
# from scrapy.crawler import CrawlerProcess
from scrapy.selector import Selector
from nba_gamelog.items import NBA_Item


class NBA_Spider(Spider):
    name = 'NBA_Spider'
    allowed_urls = ['www.nba.com']
    days = range(1, 32)
    months = range(10, 13) + range(1, 5)
    years = range(2010, 2016)
    start_urls = []
    for year in years:
        for month in months:
            for day in days:
                m = str(month).zfill(2)
                d = str(day).zfill(2)
                start_urls.append('http://www.nba.com/gameline/{}{}{}/'.format(\
                                                                        year, str(month).zfill(2), \
                                                                        str(day).zfill(2)) \
                             )

    def parse(self, response):
        # response.css("a.nbaFnlMnRecapDiv::attr('href')")

        if response.css("a.recapAnc::attr('href')"):
            for href in response.css("a.recapAnc::attr('href')"): # [0:1] only getting the first link
                url = response.urljoin(href.extract())
                game_id = re.search('games/(.+?)/gameinfo', url).group(1).replace('/', '_')
                request = Request(url, callback=self.parse_item)
                request.meta['game_id'] = game_id
                yield request
        elif response.css("div.nbaFnlMnRecapDiv a::attr('href')"):
            for href in response.css("div.nbaFnlMnRecapDiv a::attr('href')"): # [0:1] only getting the first link
                url = response.urljoin(href.extract())
                game_id = re.search('games/(.+?)/gameinfo', url).group(1).replace('/', '_')
                request = Request(url, callback=self.parse_item)
                request.meta['game_id'] = game_id
                yield request

    def parse_item(self, response):
        rows = response.xpath('//*[@id="nbaGITeamStats"]/tr').extract()
        print 'Game ID: ', response.meta['game_id']

        for row in rows:
            player = Selector(text=row).xpath('//td[1]/a/text()').extract()
            total = Selector(text=row).xpath('//td[1]/text()').extract()

            pos = Selector(text=row).xpath('//td[2]/text()').extract()
            _min = Selector(text=row).xpath('//td[3]/text()').extract()
            FGM_A = Selector(text=row).xpath('//td[4]/text()').extract()
            _3PM_A = Selector(text=row).xpath('//td[5]/text()').extract()
            FTM_A = Selector(text=row).xpath('//td[6]/text()').extract()
            plus_minus = Selector(text=row).xpath('//td[7]/text()').extract()
            OFF = Selector(text=row).xpath('//td[8]/text()').extract()
            DEF = Selector(text=row).xpath('//td[9]/text()').extract()
            TOT = Selector(text=row).xpath('//td[10]/text()').extract()
            AST = Selector(text=row).xpath('//td[11]/text()').extract()
            PF = Selector(text=row).xpath('//td[12]/text()').extract()
            ST = Selector(text=row).xpath('//td[13]/text()').extract()
            TO = Selector(text=row).xpath('//td[14]/text()').extract()
            BS = Selector(text=row).xpath('//td[15]/text()').extract()
            BA = Selector(text=row).xpath('//td[16]/text()').extract()
            PTS = Selector(text=row).xpath('//td[17]/text()').extract()

            item = NBA_Item()
            item['player'] = player
            item['pos'] = pos
            item['_min'] = _min
            item['FGM_A'] = FGM_A
            item['_3PM_A'] = _3PM_A
            item['FTM_A'] = FTM_A
            item['plus_minus'] = plus_minus
            item['OFF'] = OFF
            item['DEF'] = DEF
            item['TOT'] = TOT
            item['AST'] = AST
            item['PF'] = PF
            item['ST'] = ST
            item['TO'] = TO
            item['BS'] = BS
            item['BA'] = BA
            item['PTS'] = PTS

            print "TOTAL: ", total
            print "Class type: ", type(total)
            if not item['player'] and total == [u'Total']:
                item['player'] = [response.meta['game_id']]

            yield item

# class NBA_Spider_2(Spider):
#     name = 'NBA_Spider_2'
#     allowed_urls = ['www.nba.com']
#     days = range(26, 27)
#     months = range(1, 13)
#     years = range(2005, 2016)
#     start_urls = []

#     for i in days:
#         start_urls.append('http://www.nba.com/gameline/201602%d/' % i)

#     def parse(self, response):
#         for href in response.css("a.recapAnc::attr('href')"): # [0:1] only getting the first link
#             url = response.urljoin(href.extract())
#             game_id = re.search('games/(.+?)/gameinfo', url).group(1).replace('/', '_')
#             request = Request(url, callback=self.parse_item)
#             request.meta['game_id'] = game_id
#             yield request

#     def parse_item(self, response):
#         rows = response.xpath('//*[@id="nbaGITeamStats"]/tr').extract()
#         print 'Game ID: ', response.meta['game_id']

#         for row in rows:
#             player = Selector(text=row).xpath('//td[1]/a/text()').extract()
#             total = Selector(text=row).xpath('//td[1]/text()').extract()

#             pos = Selector(text=row).xpath('//td[2]/text()').extract()
#             _min = Selector(text=row).xpath('//td[3]/text()').extract()
#             FGM_A = Selector(text=row).xpath('//td[4]/text()').extract()
#             _3PM_A = Selector(text=row).xpath('//td[5]/text()').extract()
#             FTM_A = Selector(text=row).xpath('//td[6]/text()').extract()
#             plus_minus = Selector(text=row).xpath('//td[7]/text()').extract()
#             OFF = Selector(text=row).xpath('//td[8]/text()').extract()
#             DEF = Selector(text=row).xpath('//td[9]/text()').extract()
#             TOT = Selector(text=row).xpath('//td[10]/text()').extract()
#             AST = Selector(text=row).xpath('//td[11]/text()').extract()
#             PF = Selector(text=row).xpath('//td[12]/text()').extract()
#             ST = Selector(text=row).xpath('//td[13]/text()').extract()
#             TO = Selector(text=row).xpath('//td[14]/text()').extract()
#             BS = Selector(text=row).xpath('//td[15]/text()').extract()
#             BA = Selector(text=row).xpath('//td[16]/text()').extract()
#             PTS = Selector(text=row).xpath('//td[17]/text()').extract()

#             item = NBA_Item()
#             item['player'] = player
#             item['pos'] = pos
#             item['_min'] = _min
#             item['FGM_A'] = FGM_A
#             item['_3PM_A'] = _3PM_A
#             item['FTM_A'] = FTM_A
#             item['plus_minus'] = plus_minus
#             item['OFF'] = OFF
#             item['DEF'] = DEF
#             item['TOT'] = TOT
#             item['AST'] = AST
#             item['PF'] = PF
#             item['ST'] = ST
#             item['TO'] = TO
#             item['BS'] = BS
#             item['BA'] = BA
#             item['PTS'] = PTS

#             print "TOTAL: ", total
#             print "Class type: ", type(total)
#             if not item['player'] and total == [u'Total']:
#                 item['player'] = [response.meta['game_id']]

#             yield item

# process = CrawlerProcess()
# process.crawl(NBA_Spider)
# process.crawl(NBA_Spider_2)
# process.start()


# =======================================================================================
# player = Field()
# pos = Field()
# min = Field()
# FGM_A = Field()
# _3PM_A = Field()
# FTM_A = Field()
# plus_minus = Field()
# OFF = Field()
# DEF = Field()
# TOT = Field()
# AST = Field()
# PF = Field()
# ST = Field()
# TO = Field()
# BS = Field()
# BA = Field()
# PTS = Field()

# <td id="nbaGIBoxNme" class="b"><a href="/playerfile/marvin_williams/index.html">M. Williams</a></td>
# <td class="nbaGIPosition">F</td>
# <td>34:53</td>
# <td>9-13</td>
# <td>5-9</td>
# <td>3-4</td>
# <td>+1</td>
# <td>2</td>
# <td>11</td>
# <td>13</td>
# <td>1</td>
# <td>2</td>
# <td>1</td>
# <td>1</td>
# <td>2</td>
# <td>0</td>
# <td>26</td>
