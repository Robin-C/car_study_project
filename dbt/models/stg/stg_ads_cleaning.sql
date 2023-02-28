with raw as (
    select *
    from {{ ref('raw_ads') }}
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
         , scraped_at
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
         , scraped_at
    from color_cleaning
    left join {{ ref('mapping_models') }} mod on upper(color_cleaning.model) = mod.model
),

final as (
    select *
    from model_cleaning
)

select *
from final