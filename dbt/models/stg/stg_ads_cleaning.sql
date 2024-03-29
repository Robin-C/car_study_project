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

trim_cleaning as (
    select ad_id
         , url
         , region_cleaning.model
         , coalesce(t.trim_refined, 'MISSING') as trim
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
         , coalesce(trim_level::text, 'MISSING') as trim_level
    from region_cleaning
    left join {{ ref('mapping_trim') }} t on region_cleaning.trim = t.trim and region_cleaning.model = t.model
),

final as (
    select *
    from trim_cleaning
)

select *
from final