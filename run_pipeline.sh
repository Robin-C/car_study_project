#!/bin/bash

run() {
  $*
  if [ $? -ne 0 ]
  then
    echo "$* failed with exit code $?"
    return 1
  else
    return 0
  fi
}


run docker exec scrapper scrapy crawl lacentrale --logfile log.log && run docker exec dbt dbt run
