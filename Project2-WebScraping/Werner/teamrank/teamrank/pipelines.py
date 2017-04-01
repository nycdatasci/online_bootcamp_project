# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html


class NBA_Pipeline(object):
    def __init__(self):
        self.filename = 'NBA_Stat.txt'

    def open_spider(self, spider):
        self.file = open(self.filename, 'wb')

    def close_spider(self, spider):
        self.file.close()

    def process_item(self, item, spider):
        line = str(item['Rank'][0]) + '\t' + \
               str(item['Team'][0]) + '\t' + \
               str(item['Current_Yr_Off'][0]) + '\t' + \
               str(item['Last_3'][0]) + '\t' + \
               str(item['Last_1'][0]) + '\t' + \
               str(item['Home'][0]) + '\t' + \
               str(item['Away'][0]) + '\t' + \
               str(item['Last_Yr_Off'][0]) + '\n'
        self.file.write(line)
        return item
