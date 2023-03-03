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
	 , max(started_scrape_at) over(partition by ad_id) as last_scraped_at
     , max(scrape_rank) over(partition by ad_id) as last_scrape_rank
	 , count(*) over(partition by ad_id) as number_scraped
	 , max(published_at) over(partition by ad_id) as published_at 
from stg_ads_scrape_rank
group by ad_id, url, model, trim, scrape_rank, price, seller, year, registered_on, km, transmission, engine, hp, color, efficiency, co2, site_rec, region, published_at, started_scrape_at
),

set_status as (
    select *
		 , case when max(last_scrape_rank) over() - last_scrape_rank > 4 then last_scraped_at::date else null end as sold_at	
         , case when max(last_scrape_rank) over() - last_scrape_rank > 4 then 'SOLD' else 'ONGOING' end as status --if we havent seen a car in ~2 days then we assume it's been sold
		 
    from summary
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21
),

calculate_number_of_days_to_sell as (
	select *
		 , sold_at - published_at + 1 as time_to_sell
	from set_status
),

final as (
    select *
    from calculate_number_of_days_to_sell
	where published_at <> '2000-01-01' and status = 'SOLD'
)

select *
from final