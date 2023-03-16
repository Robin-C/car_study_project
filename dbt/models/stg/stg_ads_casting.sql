with raw as (
    select *
    from {{ ref('raw_ads') }}
),

correct_types as (
    select ad_id::bigint as ad_id
         , url
         , model
         , trim
         , replace(regexp_replace(price, '[^\w]+','', 'g'), '€', '')::integer as price --don't ask me why this works
         , seller
         , to_date(registered_on, 'DD/MM/YYYY') as registered_on
         , year::integer as year
         , regexp_replace(km, '[^\w]+','', 'g')::integer as km
         , transmission
         , engine
         , replace(hp, '(DIN) ', '') as hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , case when published_since is null then scraped_at::date
                when regexp_replace(regexp_replace(published_since, '\D+', '', 'g'),'[^\w]+','')::integer = 60 then '2022-12-30'
                else scraped_at::date - regexp_replace(regexp_replace(published_since, '\D+', '', 'g'),'[^\w]+','')::integer
           end as published_at
         , scraped_at
         , started_scrape_at
    from raw
),

final as (
    select *
    from correct_types
)

select *
from final

