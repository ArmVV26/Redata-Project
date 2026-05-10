/*
    Construye la tabla de referencia de componentes de precio a partir del nombre 
    del grupo del componente de presente en el modelo staging market.
    Granularidad: component_name
    Clave: component_id, generada a partir de component_name. 
*/

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
        component_id::varchar                                       as redata_component_name,
        component_name::varchar                                     as component_name,
        group_name::varchar                                         as group_name,
        is_composite::boolean                                       as is_composite
    from src_market
    
)

select
    component_id,
    redata_component_name,
    component_name,
    group_name,
    is_composite
from renamed_casted