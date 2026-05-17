with

src_price_component as (

    select
        component_id,
        redata_component_id,
        component_name,
        group_name,
        is_composite
    from {{ ref('ref_price_component_check_snp') }}
    where dbt_valid_to is null

)

select
    component_id,
    redata_component_id,
    component_name,
    group_name,
    is_composite
from src_price_component