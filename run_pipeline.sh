#!/bin/bash

docker exec scrapper scrapy crawl lacentrale --logfile /car_study/scrapper/log.log && docker exec dbt dbt seed && docker exec dbt dbt run
