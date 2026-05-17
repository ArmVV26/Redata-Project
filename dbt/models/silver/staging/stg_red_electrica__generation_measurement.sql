/*
    =======================================================================
    stg_red_electrica__generation_measurement
    -----------------------------------------------------------------------
    Modelo staging de mediciones de generacion electrica de REData.

    Capa: Silver / Staging
    Origen: source('redata_raw', 'generation_response')
    Materialización: view
    Granularidad: request_id + redata_technology_id + time_trunc + datetime_ree

    Aplana la respuesta JSON de estructura de generacion, dejando una fila por
    tecnologia, granularidad temporal y fechas REE.
    =======================================================================
*/

with
 
src_generation_measurement as (

    select 
        request_id,
        loaded_at,
        endpoint_name,
        time_trunc,
        raw_json        
    from {{ source('redata_raw', 'generation_response') }}

),
 
flattened_json as (

    select
        s.request_id,
        s.loaded_at,
        s.endpoint_name,
        s.time_trunc,
        inc.value:id::varchar                           as redata_technology_id,
        inc.value:attributes:title::varchar             as technology_name,
        inc.value:attributes:type::varchar              as energy_group,
        inc.value:attributes:composite::boolean         as is_composite,
        val.value:datetime::varchar                     as datetime_str,
        val.value:value::varchar                        as value_mwh,
        val.value:percentage::varchar                   as percentage
    from src_generation_measurement s,

        -- Desanida los bloques principales de la respuesta de REData
        lateral flatten(input => s.raw_json:included) inc,
        -- Cada componente contiene una serie temporal de valores
        lateral flatten(input => inc.value:attributes:values) val

),
 
renamed_casted as (
    
    select
        -- Campos de trazabilidad de la ingesta
        request_id::varchar                                 as request_id,
        loaded_at::timestamp_ntz                            as loaded_at,
        endpoint_name::varchar                              as endpoint_name,

        -- Normalizacion de atributos descriptivos
        {{ clean_text('time_trunc') }}::varchar             as time_trunc,
        try_to_number(redata_technology_id)                 as redata_technology_id,
        {{ clean_text('technology_name') }}::varchar        as technology_name,
        {{ clean_text('energy_group') }}::varchar           as energy_group,

        -- Campos propios de la medicion
        is_composite::boolean                               as is_composite,
        try_to_timestamp_ntz(datetime_str)                  as datetime_ree,
        try_to_double(value_mwh)                            as value_mwh,
        try_to_double(percentage)                           as source_percentage
    from flattened_json

)
 
select 
    request_id,
    loaded_at,
    endpoint_name,
    time_trunc,
    redata_technology_id,
    technology_name,
    energy_group,
    is_composite,
    datetime_ree,
    value_mwh,
    source_percentage
from renamed_casted