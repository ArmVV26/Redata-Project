with

src_region as (

    select
        region_id,
        region_name,
        region_type
    from {{ ref('ref_regions') }}

)

select
    region_id,
    region_name,
    region_type
from src_region