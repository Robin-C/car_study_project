with seed as (
    select *
    from {{ ref('models') }}
),

final as (
    select *
    from seed
)

select *
from final