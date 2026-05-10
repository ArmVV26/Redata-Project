with

src_market as (

    select distinct
        component_id,
        component_name,
        group_name,
        is_composite
    from {{ ref('stg_market_measurement') }}

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key(['component_name']) }}  as component_id,
        component_id::varchar                                       as standard_component_name,
        component_name::varchar                                     as component_name,
        group_name::varchar                                         as group_name,
        is_composite::boolean                                       as is_composite
    from src_market
    
)

select
    component_id,
    standard_component_name,
    component_name,
    group_name,
    is_composite
from renamed_casted