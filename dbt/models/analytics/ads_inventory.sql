with dates as (
	select *
	from {{ ref('dim_date') }}
	where date >= '2022-12-31'
),

summary as (
	select *
	from {{ ref('ads_summary_wide') }}
),

final as (
	select date
		, model
			, class
			, color
			, engine
			, region
			, transmission
			, year
			, count(*) as count
			, avg(price)::integer as price
			, avg(km)::integer as km
	from dates
	left join summary on date >= published_at and (date <= sold_at or sold_at is null)
	group by 1,2,3,4,5,6,7,8
	order by 1
)

select *
from final
