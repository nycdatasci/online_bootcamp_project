# Pipelines - validate all fields for each item, save as JSON

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
        self.file = open('%s.json' %(spider.name), 'wb')

    def close_spider(self, spider):
        self.file.close()

    def process_item(self, item, spider):
        line = json.dumps(dict(item)) + "\n"
        self.file.write(line)
        return item

