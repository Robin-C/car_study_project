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
