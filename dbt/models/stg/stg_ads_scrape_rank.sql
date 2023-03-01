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