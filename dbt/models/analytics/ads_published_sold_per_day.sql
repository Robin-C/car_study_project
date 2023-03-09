with ads_summary_wide as (
    select *
    from {{ ref('ads_summary_wide') }}
),

dates as (
    select date
    from {{ ref('dim_date') }}
    where 1=1
    and is_next_month = false
),

count_published as (
    select published_at as date
         , model
         , class
         , color
         , engine
         , hp
         , km
         , price
         , region
         , status
         , transmission
         , year
         , count(*) as count_published
         , 0 as count_sold
    from ads_summary_wide
    group by 1,2,3,4,5,6,7,8,9,10,11,12
),

count_sold as (
    select sold_at
         , model
         , class
         , color
         , engine
         , hp
         , km
         , price
         , region
         , status
         , transmission
         , year
         , 0 as count_published
         , count(*) as count_sold
    from ads_summary_wide
    where status = 'SOLD'
    group by 1,2,3,4,5,6,7,8,9,10,11,12         
),

unioned_count as (
    select date
         , t.model
         , t.class
         , t.color
         , t.engine
         , t.hp
         , t.km
         , t.price
         , t.region
         , t.status
         , t.transmission
         , t.year
         , sum(count_published) as count_published
         , sum(count_sold) as count_sold
    from (select *
        from count_published
        union all 
        select *
        from count_sold
    ) t
    group by 1,2,3,4,5,6,7,8,9,10,11,12
),


joined_with_dates as (
    select dates.date
         , model
         , class
         , color
         , engine
         , hp
         , km
         , price
         , region
         , status
         , transmission
         , year
         , coalesce(count_published, 0) as count_published
         , coalesce(count_sold, 0) as count_sold
    from dates
    left join unioned_count on unioned_count.date = dates.date
),

final as (
    select *
    from joined_with_dates
    order by 1,2,3,4,5,6,7,8,9,10,11,12   
)

select *
from final