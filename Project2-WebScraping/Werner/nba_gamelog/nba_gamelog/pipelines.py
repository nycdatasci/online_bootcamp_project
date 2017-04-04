# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html
import sys
reload(sys)
sys.setdefaultencoding('utf-8') # Need to set default to utf-8, otherwise ascii codec will give error.


class NBA_Pipeline(object):
    def __init__(self):
        self.filename = 'NBA_Stat.csv'

    def open_spider(self, spider):
        self.file = open(self.filename, 'wb')

    def close_spider(self, spider):
        self.file.close()

    def process_item(self, item, spider):
        line = str(item['player'][0]) + '\t' + \
               str(item['pos'][0]) + '\t' + \
               str(item['_min'][0]) + '\t' + \
               str(item['FGM_A'][0]) + '\t' + \
               str(item['_3PM_A'][0]) + '\t' + \
               str(item['FTM_A'][0]) + '\t' + \
               str(item['plus_minus'][0]) + '\t' + \
               str(item['OFF'][0]) + '\t' + \
               str(item['DEF'][0]) + '\t' + \
               str(item['TOT'][0]) + '\t' + \
               str(item['AST'][0]) + '\t' + \
               str(item['PF'][0]) + '\t' + \
               str(item['ST'][0]) + '\t' + \
               str(item['TO'][0]) + '\t' + \
               str(item['BS'][0]) + '\t' + \
               str(item['BA'][0]) + '\t' + \
               str(item['PTS'][0]) + '\n'
        self.file.write(line)
        return item

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