with raw as (
    select *
    from {{ ref('raw_ads') }}
),

correct_types as (
    select ad_id
         , url
         , model
         , trim
         , regexp_replace(replace(regexp_replace(price, '[^\w]+',''), '€', ''), '[^\w]+','')::integer as price --don't ask me why this works
         , seller
         , to_date(registered_on, 'DD/MM/YYYY') as registered_on
         , year::integer as year
         , km::integer as year
         , transmission
         , engine
         , replace(hp, '(DIN) ', '') as hp
         , color
         , efficiency
         , co2
         , site_rec
         , region
         , published_since
         , scraped_at
)

