#define priority of ITEM_PIPELINES

ITEM_PIPELINES = {'budget.pipelines.ValidateItemPipeline': 100,
				  'budget.pipelines.WriteItemPipeline': 200}