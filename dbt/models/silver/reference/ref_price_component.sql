/*
    =======================================================================
    ref_price_component
    -----------------------------------------------------------------------
    Modelo de referencia de componentes de precio.

    Capa: Silver / Reference
    Origen: stg_red_electrica__market_measurement
    Materialización: table
    Granularidad: component_name + group_name
    Clave: component_id, generada a partir de component_name y group_name.

    Construye un catalogo analitico de componentes del precio electrico a 
    partir de los datos publicados por REData.
    =======================================================================
*/

with

src_market as (

    select distinct
        component_id,
        component_name,
        group_name,
        is_composite
    from {{ ref('stg_red_electrica__market_measurement') }}

),

renamed_casted as (

    select
        -- Clave surrogate estable para analisis, independiente del endpoint de origen
        {{ dbt_utils.generate_surrogate_key([
            'component_name',
            'group_name'
        ]) }}                                                       as component_id,

        -- Identificador original de REData conservado para trazabilidad
        component_id::varchar                                       as redata_component_id,
        trim(component_name)::varchar                               as component_name,
        trim(group_name)::varchar                                   as group_name,
        is_composite::boolean                                       as is_composite
    from src_market
    
)

select
    component_id,
    redata_component_id,
    component_name,
    group_name,
    is_composite
from renamed_casted