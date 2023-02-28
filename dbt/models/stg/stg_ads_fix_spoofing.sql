with stg_ads_cleaning as (
    select *
    from {{ ref('stg_ads_cleaning') }}
),

spoofing_fixed as (
    select ad_id
         , url
         , model
         , trim
         , price
         , seller
         , registered_on
         , year - 1 as year
         , km * {{ var('spoof_percent') }}
         , transmission
         , engine
         , hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , scraped_at
)

