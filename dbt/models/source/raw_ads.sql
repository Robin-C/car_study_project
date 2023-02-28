with source as (
    select *
    from {{ source('raw', 'ads') }}
),

final as (
    select *
    from source
)

select *
from final