# -*- coding: utf-8 -*-

# Scrapy settings for demo project
#
# For simplicity, this file contains only settings considered important or
# commonly used. You can find more settings consulting the documentation:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#     http://scrapy.readthedocs.org/en/latest/topics/downloader-middleware.html
#     http://scrapy.readthedocs.org/en/latest/topics/spider-middleware.html

BOT_NAME = 'nba'

SPIDER_MODULES = ['nba.spiders']
NEWSPIDER_MODULE = 'nba.spiders'

DOWNLOAD_DELAY = 3
ITEM_PIPELINES = {
   'nba.pipelines.NBA_Pipeline': 100,
}
