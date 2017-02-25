# -*- coding: utf-8 -*-
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: http://doc.scrapy.org/en/latest/topics/item-pipeline.html
import json
from scrapy.exceptions import DropItem

class ValidateItemPipeline(object):
	def process_item(self,item,spider):
		if not all(item.values()):
			raise DropItem('Missing Values!')
		else:
			return item

class JsonWriterPipeline(object):

    def open_spider(self, spider):
        self.file = open('GTM_output.json', 'wb')

    def close_spider(self, spider):
        self.file.close()

    def process_item(self, item, spider):
        line = json.dumps(dict(item)) + "\n"
        self.file.write(line)
        return item

