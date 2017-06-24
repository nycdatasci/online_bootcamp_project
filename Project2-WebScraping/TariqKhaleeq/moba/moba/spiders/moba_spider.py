# -*- coding: utf-8 -*-
from scrapy.selector import Selector
from moba.items import MobaItem
from scrapy import Spider

class MobaSpiderSpider(Spider):
    name = "moba_spider"
    allowed_domains = ["http://www.mobafire.com/league-of-legends/champions"]
    start_urls = ['http://www.mobafire.com/league-of-legends/champions/']

    def parse(self, response):
        rows = response.xpath('//*[@id="content"]/div/div[2]/div[1]/div[2]/a').extract()

        for row in rows:
            name = Selector(text=row).xpath('//div[@class="champ-list__item__name"]/b/text()').extract()
            alias = Selector(text=row).xpath('//div[@class="champ-list__item__name"]/span/text()').extract()
            pos1 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/span/b[1]/text()').extract()
            pickrate1 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/b[1]/text()').extract()
            winrate1 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/i[1]/text()').extract()
            pos2 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/span/b[2]/text()').extract()
            pickrate2 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/b[2]/text()').extract()
            winrate2 = Selector(text=row).xpath('//div[@class="champ-list__item__role"]/i[2]/text()').extract()
            damage = Selector(text=row).css('div[class="radial-stats"] ::attr(rating)').extract()[0]
            thoughness = Selector(text=row).css('div[class="radial-stats"] ::attr(rating)').extract()[1]
            cc = Selector(text=row).css('div[class="radial-stats"] ::attr(rating)').extract()[2]
            mobility = Selector(text=row).css('div[class="radial-stats"] ::attr(rating)').extract()[3]
            utility = Selector(text=row).css('div[class="radial-stats"] ::attr(rating)').extract()[4]
            if not (Selector(text=row).xpath('//div[@class="champ-list__item__role"]/span/b[2]/text()').extract()):
                pos2 = '-'
                pickrate2 = '-'
                winrate2 = '-'

            item = MobaItem()
            item['name'] = name
            item['alias'] = alias
            item['pos1'] = pos1
            item['pickratepos1'] = pickrate1
            item['winrate1'] = winrate1
            item['pos2'] = pos2
            item['pickratepos2'] = pickrate2
            item['winrate2'] = winrate2
            item['damage'] = damage
            item['toughness'] = thoughness
            item['cc'] = cc
            item['mobility'] = mobility
            item['utility'] = utility

            yield item
