with dates as (
	select *
	from {{ ref('dim_date') }}
	where date >= '2023-02-27'
),

summary as (
	select *
         , case when published_at <= '2023-02-27' then '2023-02-27' else published_at end as date_fixed
	from {{ ref('ads_summary_wide') }}
),

final as (
	select date
         , ad_id
		 , model
		 , class
		 , color
		 , engine
		 , region
		 , transmission
		 , recency
         , km_bracket
		 , count(*) as count
		 , avg(price)::integer as price
		 , avg(km)::integer as km
	from dates
	left join summary on date >= date_fixed and (date < sold_at or sold_at is null)
	group by 1,2,3,4,5,6,7,8,9,10
	order by 1
)

select *
from final