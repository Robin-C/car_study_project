with ads_summary as (
    select *
    from {{ ref('ads_summary') }}
),

dim_models as (
    select *
    from {{ ref('models') }}
),

recency as (
    select *
    from {{ ref('mapping_years') }}
),

km_bracket as (
    select *
    from {{ ref('mapping_km') }}
),

joined as (
    select ads_summary.*
         , dim_models.class
         , coalesce(recency, '> 10 years') as recency
         , coalesce(km_bracket, ']150k,	∞[') as km_bracket
    from ads_summary
    inner join dim_models on dim_models.model = ads_summary.model
    left join recency on ads_summary.year = recency.year
    left join km_bracket on ads_summary.km > km_bracket.km_lower_range and ads_summary.km <= km_bracket.km_upper_range
),

final as (
    select *
    from joined
)

select *
from final