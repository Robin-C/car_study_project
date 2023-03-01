# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
from itemadapter import ItemAdapter
import pandas as pd
from sqlalchemy import create_engine
import sys

conn_string = "postgresql://postgres:mypgdbpass@89.40.11.101/postgres"
engine = create_engine(conn_string)


class ScrapperPipeline:
    data = []

    def process_item(self, item, spider):
        self.data.append(item)
        return item
     

    def close_spider(self, spider):
        if len(self.data) > 12000:
            df = pd.DataFrame.from_dict(self.data)
            print(df)
            insert = df.to_sql(
                "ads", con=engine, schema="raw", if_exists="append", index=False
            )
        else:
            sys.exit(1) # we didnt scrape the whole thing for some reason

