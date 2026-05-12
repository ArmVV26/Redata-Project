with

src_price_component as (

    select
        component_id,
        redata_component_id,
        component_name,
        group_name,
        is_composite
    from {{ ref('ref_price_component') }}

),

renamed_casted as (

    select
        component_id::varchar               as component_id,
        redata_component_id::varchar        as redata_component_id,
        component_name::varchar             as component_name,
        group_name::varchar                 as group_name,
        is_composite::boolean               as is_composite
    from src_price_component

)

select
    component_id,
    redata_component_id,
    component_name,
    group_name,
    is_composite
from renamed_casted