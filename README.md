# Car study

The goal of this notebook is for me, Robin, to explain the different design decisions I took and why I took them. 

For insights, you can head to [hex.tech](hex.tech) notebook.

## Data source

Our unique data source is the website lacentrale.fr . This website is the biggest used car ads platform in France boasting about 300k car for sale at any point in time.

I chose this website because most of us will once in a while buy or sell our car. This is a big financial decision and surely one we can try to [minimize the amount of regret](https://towardsdatascience.com/introduction-to-regret-in-reinforcement-learning-f5b4a28953cd#).

Instinctively, I wanted to see what are the factors susceptible to make a car sell:
- for a higher price
- quicker (number of days between ad published and sold)

This way, one can make a better decision when they buy a car as to make the future sell of their vehicle easier or at least know the hidden cost (in terms of €€ and/or time) of their decision.

The website does not have a public api. I had to scrape the website using the python library [scrapy](https://scrapy.org/). This was the first challenge and it forced me brush up on my xpath selector skills. You can find the code for the scrapper [here](https://github.com/Robin-C/car_study_project/tree/master/scrapper). As to not overload the server, I had to use the autothrotling capabilities of scrapy. One full scrape takes close to 3 hours.

This is what an ad looks like:

```
{
  'ad_id': '87102572911'
, 'url': 'https://www.lacentrale.fr/auto-occasion-annonce-87102572911.html'
, 'model': 'VOLKSWAGEN TIGUAN II'
, 'trim': '1.4 TSI 150 CARAT EXCLUSIVE'
, 'price': '40 170 €'
, 'seller': 'PRO'
, 'registered_on': '10/04/2019'
, 'year': '2019'
, 'km': '69 575'
, 'transmission': 'Automatique'
, 'engine': 'Essence'
, 'hp': '(DIN) 150 ch'
, 'color': 'gris metal'
, 'efficiency': '5,5 L/100 km '
, 'co2': '139 g/km'
, 'site_rec': 'Au dessus du marché'
, 'region': '92'
, 'published_since': ' il y a 26 jours'
, 'scraped_at': 2023-03-01 22:35:54.765582
, 'started_scrape_at': 2023-03-01 20:10:32.073203
}
```

One interesting thing to note is that early on, I wanted to know how long it takes for a car to sell. Not having access to an api, I could not easily determinate if a car sold or not. Indeed, when a seller pulls their ads (assuming it sold), the url for the ad just starts returning 404 error.

One solution would be every day to:

1) Send a http request to the url of each ad to see if it sold
2) Scrape ads as usual

I instead chose to only go with 2) and then inside the datawarehouse, when the data ingests, I could compare yesterday's batch against the fresh one and if one ad was missing I would mark it as sold. In theory of course. In practice, I opted to wait for a couple of batches to pass before marking a car as sold because for some reason, sometimes, the scraper would miss the ad.

For orchestrastion, I used CRON for ease of installation. For a beefier, more complex project I would have taken the time to set up Airflow (or Dagster).

## Transformations

For transformations, I used dbt on a self hosted containerized docker postgres instance.

There were 4 big steps, each with its own dbt model for ease of understanding.

### stg_ads_casting
Goal of this model is to cast the column to their correct types since most columns were ingested as text and this wasn't the scrapper's role to do so (and I'm also not a big fan of pandas). Notice the us of regex to remove the spaces which weren't simple space bar spaces for some reason.
```
with raw as (
    select *
    from {{ ref('raw_ads') }}
),

correct_types as (
    select ad_id::bigint as ad_id
         , url
         , model
         , trim
         , replace(regexp_replace(price, '[^\w]+','', 'g'), '€', '')::integer as price
         , seller
         , to_date(registered_on, 'DD/MM/YYYY') as registered_on
         , year::integer as year
         , regexp_replace(km, '[^\w]+','', 'g')::integer as km
         , transmission
         , engine
         , replace(hp, '(DIN) ', '') as hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , case when published_since is null then scraped_at::date
                when regexp_replace(regexp_replace(published_since, '\D+', '', 'g'),'[^\w]+','')::integer = 60 then '2000-01-01'
                else scraped_at::date - regexp_replace(regexp_replace(published_since, '\D+', '', 'g'),'[^\w]+','')::integer
           end as published_at
         , scraped_at
         , started_scrape_at
    from raw
),

final as (
    select *
    from correct_types
)

select *
from final
```

### stg_ads_cleaning
Here, we grouped some fields together. For some reason, car manufacturers like the name of their colors to be very fancy. So I made a custom table to group colors together: white, black, red, blue, yellow...

Same thing for the model field where some of the cars have different generations which I grouped under a single one (I prefer to use the year field to see when a new generation stands out).

Finally, the different department that I grouped under region. The idea is down the road to see if an identical car sells for cheaper in some regions of France.

```
with raw as (
    select *
    from {{ ref('stg_ads_casting') }}
),

color_cleaning as (
    select ad_id
         , url
         , model
         , trim
         , price
         , seller
         , registered_on
         , year
         , km
         , transmission
         , engine
         , hp
         , coalesce(col.color_refined, 'MISSING') as color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , published_at
         , scraped_at
         , started_scrape_at
    from raw
    left join {{ ref('mapping_colors') }} col on lower(raw.color) = col.color
),

model_cleaning as (
    select ad_id
         , url
         , coalesce(mod.model_refined, 'MISSING') as model
         , trim
         , price
         , seller
         , registered_on
         , year
         , km
         , transmission
         , engine
         , hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , published_at
         , scraped_at
         , started_scrape_at
    from color_cleaning
    left join {{ ref('mapping_models') }} mod on upper(color_cleaning.model) = mod.model
),

region_cleaning as (
    select ad_id
         , url
         , model
         , trim
         , price
         , seller
         , registered_on
         , year
         , km
         , transmission
         , engine
         , hp
         , color
         , efficiency
         , co2
         , site_rec
         , reg.region as region
         , published_since
         , published_at
         , scraped_at
         , started_scrape_at
    from model_cleaning
    left join {{ ref('mapping_regions') }} reg on reg.dpt::integer = model_cleaning.region::integer
),

final as (
    select *
    from region_cleaning
)

select *
from final
```
### stg_ads_fix_spoofing

That step is interesting. The website, to protect its data, provided my scrapper with fake figures on some fields. I figured they would consistently make the car 1 year younger, with between 5 and 25% more km and and between 5 and 25% more expensive than it actually was when one would visit their website.

I did a quick analysis of the phenomenon and could not find a way to fix their spoofing other than using an average of 15%. It won't affect the result of my study much since we've got a lot of data points and we are more looking for tendancies rather than actual figures.

```
with stg_ads_cleaning as (
    select *
    from {{ ref('stg_ads_cleaning') }}
),

spoofing_fixed as (
    select ad_id
         , url
         , model
         , trim
         , (price / {{ var('spoof_percent') }})::integer as price
         , seller
         , registered_on - 365 as registered_on
         , year - 1 as year
         , (km / {{ var('spoof_percent') }})::integer as km
         , transmission
         , engine
         , hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_at
         , scraped_at
         , started_scrape_at
    from stg_ads_cleaning  
),

final as (
    select *
    from spoofing_fixed
)

select *
from final
```
### stg_ads_scrape_rank
The final transformation. This step makes it possible to calculate if a car was sold or not. Basically, every time the scraper runs, there is a unique timestamp. We transform this unique timestamp into an incremental "run id" which will be used later to say that if we haven't seen a car in a while then we can mark it a sold. 
```
with stg_ads_fix_spoofing as (
    select *
    from {{ ref('stg_ads_fix_spoofing') }}
),

scrape_rank as (
    select started_scrape_at
         , rank() over(order by started_scrape_at) as rank
    from stg_ads_fix_spoofing
    group by 1
),

joined as (
    select stg_ads_fix_spoofing.*
         , scrape_rank.rank as scrape_rank
    from stg_ads_fix_spoofing
    inner join scrape_rank on scrape_rank.started_scrape_at = stg_ads_fix_spoofing.started_scrape_at
),

final as (
    select *
    from joined
)

select *
from final
```

### analytics_ads_summary
This is the the finished product, the table our bi tool will run queries against. We group by ad_id to get a list of unique id. Note the where clause in the last cte so we only analyze the cars that have been sold.

```
with stg_ads_scrape_rank as (
    select *
    from {{ ref('stg_ads_scrape_rank') }}
),

summary as (
    select distinct ad_id
	 , url
	 , first_value(model) over(partition by ad_id order by scrape_rank desc) as model
	 , first_value(trim) over(partition by ad_id order by scrape_rank desc) as trim
	 , avg(price) over(partition by ad_id)::integer as price
	 , first_value(seller) over(partition by ad_id order by scrape_rank desc) as seller
	 , first_value(year) over(partition by ad_id order by scrape_rank desc) as year
	 , first_value(registered_on) over(partition by ad_id order by scrape_rank desc) as registered_on
	 , avg(km) over(partition by ad_id)::integer as km
	 , first_value(transmission) over(partition by ad_id order by scrape_rank desc) as transmission
	 , first_value(engine) over(partition by ad_id order by scrape_rank desc) as engine
	 , first_value(hp) over(partition by ad_id order by scrape_rank desc) as hp
	 , first_value(color) over(partition by ad_id order by scrape_rank desc) as color
	 , first_value(efficiency) over(partition by ad_id order by scrape_rank desc) as efficiency
	 , first_value(co2) over(partition by ad_id order by scrape_rank desc) as co2
	 , first_value(site_rec) over(partition by ad_id order by scrape_rank desc) as site_rec
	 , first_value(region) over(partition by ad_id order by scrape_rank desc) as region
	 , max(published_at) over(partition by ad_id) as published_at 
	 , max(started_scrape_at) over(partition by ad_id) as last_scraped_at
     , max(scrape_rank) over(partition by ad_id) as last_scrape_rank
	 , count(*) over(partition by ad_id) as number_scraped 
from stg_ads_scrape_rank
group by ad_id, url, model, trim, scrape_rank, price, seller, year, registered_on, km, transmission, engine, hp, color, efficiency, co2, site_rec, region, published_at, started_scrape_at
),

set_status as (
    select *
         , case when max(last_scrape_rank) over() - last_scrape_rank > 4 then 'SOLD' else 'ONGOING' end as status --if we havent seen a car in ~2 days then we assume it's been sold
		 , case when max(last_scrape_rank) over() - last_scrape_rank > 4 then last_scraped_at::date else null end as sold_at
    from summary
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
),

calculate_number_of_days_to_sell as (
	select *
		 , sold_at - published_at as time_to_sell
	from set_status
),

final as (
    select *
    from calculate_number_of_days_to_sell
	where published_at <> '2000-01-01' and status = 'SOLD'
)

select *
from final
```
