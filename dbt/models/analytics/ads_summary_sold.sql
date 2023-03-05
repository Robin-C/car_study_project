with ads_summary as (
	select *
	from {{ ref('ads_summary') }}
),

final as (
	select *
	from ads_summary
	where status = 'SOLD'
)

select *
from final