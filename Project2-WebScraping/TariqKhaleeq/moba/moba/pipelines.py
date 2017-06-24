# -*- coding: utf-8 -*-

# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html


class MobaPipeline(object):
    def __init__(self):
        self.filename = "LOL_moba_champs.txt"

    def open_spider(self, spider):
        self.file = open(self.filename,'wb')

    def close_spider(self, spider):
        self.file.close()

    def process_item(self, item, spider):
        line = str(item['name'][0]) + '\t' + str(item['alias'][0]) + '\t' \
        + str(item['pos1'][0]) + '\t' + str(item['pickratepos1'][0]) + '\t' + str(item['winrate1'][0]) + '\t' \
        + str(item['pos2'][0]) + '\t' + str(item['pickratepos2'][0]) + '\t' + str(item['winrate2'][0]) + '\t' \
        + str(item['damage'][0]) + '\t' + str(item['toughness'][0]) + '\t' \
        + str(item['cc'][0]) + '\t' + str(item['mobility'][0]) + '\t'\
        + str(item['utility'][0]) + '\n'
        self.file.write(line)
        return item
