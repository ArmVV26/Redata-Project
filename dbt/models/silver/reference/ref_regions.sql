with

src_regions as (

    select
        geo_id,
        geo_name,
        geo_type
    from {{ ref('regions') }}

),

renamed_casted as (

    select
        geo_id::varchar          as region_id,
        geo_name::varchar        as region_name,
        geo_type::varchar        as region_type
    from src_regions

)

select
    region_id,
    region_name,
    region_type
from renamed_casted