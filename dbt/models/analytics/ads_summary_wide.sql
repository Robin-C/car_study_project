with ads_summary as (
    select *
    from {{ ref('ads_summary') }}
),

dim_models as (
    select *
    from {{ ref('models') }}
),

joined as (
    select ads_summary.*
         , dim_models.class
    from ads_summary
    inner join dim_models on dim_models.model = ads_summary.model
),

final as (
    select *
    from joined
)

select *
from final