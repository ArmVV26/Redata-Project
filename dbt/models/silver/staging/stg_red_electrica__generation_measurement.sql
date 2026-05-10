/*
    Staging de generacion REData.
    Aplana RAW_JSON desde BRONZE.RAW.GENERATION_RESPONSE.
    Granularidad: request_id + techonology_id + time_trunc + datetime_raw
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
        inc.value:id::varchar                       as technology_id,
        inc.value:attributes:title::varchar         as technology_name,
        inc.value:attributes:type::varchar          as energy_group,
        inc.value:attributes:composite::boolean     as is_composite,
        val.value:datetime::varchar                 as datetime_str,
        val.value:value::varchar                    as value_mwh,
        val.value:percentage::varchar               as percentage
    from src_generation_measurement s,
        lateral flatten(input => s.raw_json:included) inc,
        lateral flatten(input => inc.value:attributes:values) val

),
 
renamed_casted as (
    
    select
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at,
        endpoint_name::varchar                      as endpoint_name,
        time_trunc::varchar                         as time_trunc,
        technology_id::varchar                      as technology_id,
        technology_name::varchar                    as technology_name,
        energy_group::varchar                       as energy_group,
        is_composite::boolean                       as is_composite,
        try_to_timestamp_ntz(datetime_str)          as datetime_raw,
        try_to_double(value_mwh)                    as value_mwh,
        try_to_double(percentage)                   as percentage
    from flattened_json

)
 
select 
    request_id,
    loaded_at,
    endpoint_name,
    time_trunc,
    technology_id,
    technology_name,
    energy_group,
    is_composite,
    datetime_raw,
    value_mwh,
    percentage
from renamed_casted