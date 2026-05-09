with
 
src_market_measurement as (

    select 
        request_id,
        loaded_at,
        endpoint_name,
        time_trunc,
        raw_json        
    from {{ source('redata_raw', 'market_response') }}

),
 
flattened_json as (

    select
        s.request_id,
        s.loaded_at,
        s.endpoint_name,
        s.time_trunc,
        cont.value:id::varchar                      as component_id,
        cont.value:attributes:title::varchar        as component_name,
        inc.value:attributes:title::varchar                     as group_name,
        cont.value:attributes:composite::boolean    as is_composite,
        val.value:datetime::varchar                 as datetime_str,
        val.value:value::float                      as value_eur_mwh,
        val.value:percentage::float                 as percentage
    from stg_market_measurement s,
        lateral flatten(input => s.raw_json:included) inc,
        lateral flatten(input => inc.value:attributes:content) cont,
        lateral flatten(input => cont.value:attributes:values) val

),
 
renamed_casted as (
    
    select
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at,
        endpoint_name::varchar                      as endpoint_name,
        time_trunc::varchar                         as time_trunc,
        component_id::varchar                       as component_id,
        component_name::varchar                     as component_name,
        group_name::varchar                         as group_name,
        is_composite::boolean                       as is_composite,
        datetime_str::timestamp_ntz                 as datetime_raw,
        value_eur_mwh::float                        as value_eur_mwh,
        percentage::float                           as percentage
    from flattened_json

)
 
select *
from renamed_casted