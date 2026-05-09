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
        val.value:value::float                      as value_mwh,
        val.value:percentage::float                 as percentage
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
        datetime_str::timestamp_ntz                 as datetime_raw,
        value_mwh::float                            as value_mwh,
        percentage::float                           as percentage
    from flattened_json

)
 
select *
from renamed_casted