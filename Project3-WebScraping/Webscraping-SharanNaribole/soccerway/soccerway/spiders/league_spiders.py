import scrapy
from soccerway.items import SoccerwayItem
import unicodedata

def decompose(x):
    x = unicodedata.normalize('NFD',x).encode('ascii','ignore')
    return x.decode("utf-8")

class LeagueSpider(scrapy.Spider):
    name = "soccerway"

    NLeagues = 5 #number of leagues
    NPlayers = 15 #per league

    start_urls = [
        'http://us.soccerway.com/competitions/']

    def parse(self, response):
        self.logger.info("Visited %s", response.url)
        i = 1 
        for href in response.css('#page_competitions_1_block_competitions_popular_1-results li a::attr(href)').extract():
            yield scrapy.Request(response.urljoin(href),callback=self.parse_league)
            i += 1
            if(i > self.NLeagues): 
                break

    def parse_league(self, response):
        self.logger.info("Visited %s", response.url)
        i = 1
        for player in response.css('.player.large-link'):
            item = SoccerwayItem()
            item['id_name'] = decompose(player.css('a::text').extract()[0])
            item['league'] = decompose(response.css('h1::text').extract_first())
            print(item['id_name'])
            item['profile'] = response.urljoin(player.css('a::attr(href)').extract()[0])
            print(item['profile'])

            next_page = response.urljoin(player.css('a::attr(href)').extract()[0])
            print(next_page)

            if next_page is not None:
                request = scrapy.Request(next_page,callback = self.parse_player)
                request.meta['item'] = item
                yield(request)
            
            i += 1
            if(i > self.NPlayers):
                break
            
          
    def parse_player(self, response):
        self.logger.info("Visited %s", response.url)
        item = response.meta['item']

        item['first_name'] = decompose(response.css('dd:nth-child(2)::text').extract()[0])
        item['last_name'] = decompose(response.css('dd:nth-child(4)::text').extract()[0])
        item['club'] = decompose(response.css('.odd:nth-child(1) .team a::text').extract()[0])
        item['goals'] = int(response.css('.odd:nth-child(1) .goals::text').extract()[0])
        yield(item)
        

        
        

        
        
        
        
