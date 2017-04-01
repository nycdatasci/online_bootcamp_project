# -*- coding: utf-8 -*-

# Scrapy settings for demo project
#
# For simplicity, this file contains only settings considered important or
# commonly used. You can find more settings consulting the documentation:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#     http://scrapy.readthedocs.org/en/latest/topics/downloader-middleware.html
#     http://scrapy.readthedocs.org/en/latest/topics/spider-middleware.html

BOT_NAME = 'nba_gamelog'

SPIDER_MODULES = ['nba_gamelog.spiders']
NEWSPIDER_MODULE = 'nba_gamelog.spiders'

DOWNLOAD_DELAY = 3
ITEM_PIPELINES = {
   'nba_gamelog.pipelines.NBA_Pipeline': 100,
}
