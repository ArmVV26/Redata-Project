with

src_region as (

    select
        region_id,
        region_name,
        region_type
    from {{ ref('ref_regions') }}

),

renamed_casted as (

    select
        region_id::varchar          as region_id,
        region_name::varchar        as region_name,
        region_type                 as region_type
    from src_region

)

select
    region_id,
    region_name,
    region_type
from renamed_casted