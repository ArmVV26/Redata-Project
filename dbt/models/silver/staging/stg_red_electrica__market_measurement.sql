/*
    =======================================================================
    stg_red_electrica__market_measurement
    -----------------------------------------------------------------------
    Modelo staging de mediciones de mercado de REData.

    Capa: Silver / Staging
    Origen: source('redata_raw', 'market_response')
    Materialización: view
    Granularidad: request_id + component_id + time_trunc + datetime_ree

    Aplana la respuesta JSON de componentes de precio de la electricidad,
    normaliza los campos principales y conserva la trazabilidad de la carga.
    =======================================================================
*/

with
 
src_market_measurement as (

    select 
        request_id,
        loaded_at,
        endpoint_name,
        time_trunc,
        raw_json        
    from {{ source('redata_raw', 'market_response') }}
    where error_message is null
        and http_status_code between 200 and 299
        and raw_json is not null

),
 
flattened_json as (

    select
        s.request_id,
        s.loaded_at,
        s.endpoint_name,
        s.time_trunc,
        cont.value:id::varchar                      as component_id,
        cont.value:attributes:title::varchar        as component_name,
        inc.value:attributes:title::varchar         as group_name,
        cont.value:attributes:composite::boolean    as is_composite,
        val.value:datetime::varchar                 as datetime_str,
        val.value:value::varchar                    as value_eur_mwh,
        val.value:percentage::varchar               as percentage
    from src_market_measurement s,
        
        -- Desanida los bloques principales de la respuesta de REData
        lateral flatten(input => s.raw_json:included) inc,
        -- Cada bloque puede contener varios componentes de precio
        lateral flatten(input => inc.value:attributes:content) cont,
        -- Cada componente contiene una serie temporal de valores
        lateral flatten(input => cont.value:attributes:values) val

),
 
renamed_casted as (
    
    select
        -- Campos de trazabilidad de la ingesta
        request_id::varchar                             as request_id,
        loaded_at::timestamp_ntz                        as loaded_at,
        endpoint_name::varchar                          as endpoint_name,

        -- Normalizacion de atributos descriptivos
        {{ clean_text('time_trunc') }}::varchar         as time_trunc,
        component_id::varchar                           as component_id,
        {{ clean_text('component_name') }}::varchar     as component_name,
        {{ clean_text('group_name') }}::varchar         as group_name,

        -- Campos propios de la medicion
        is_composite::boolean                           as is_composite,
        try_to_timestamp_ntz(datetime_str)              as datetime_ree,
        try_to_double(value_eur_mwh)                    as value_eur_mwh,
        try_to_double(percentage)                       as source_percentage
    from flattened_json

)
 
select
    request_id,
    loaded_at,
    endpoint_name,
    time_trunc,
    component_id,
    component_name,
    group_name,
    is_composite,
    datetime_ree,
    value_eur_mwh,
    source_percentage
from renamed_casted