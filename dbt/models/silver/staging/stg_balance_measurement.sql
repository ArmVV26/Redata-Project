with
 
source as (

    select 
        request_id,
        loaded_at,
        endpoint_name,
        geo_id,
        time_trunc,
        raw_json        
    from {{ source('redata_raw', 'balance_response') }}

),
 
flattened_jason as (

    select
        s.request_id,
        s.loaded_at,
        s.endpoint_name,
        s.geo_id,
        s.time_trunc,
        cont.value:id::varchar                      as technology_id,
        cont.value:attributes:title::varchar        as technology_name,
        inc.value:type::varchar                     as energy_group,
        cont.value:attributes:composite::boolean    as is_composite,
        val.value:datetime::varchar                 as datetime_str,
        val.value:value::float                      as value_mwh,
        val.value:percentage::float                 as percentage
    from source s,
        lateral flatten(input => s.raw_json:included) inc,
        lateral flatten(input => inc.value:attributes:content) cont,
        lateral flatten(input => cont.value:attributes:values) val

),
 
renamed_casted as (
    
    select
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at,
        endpoint_name::varchar                      as endpoint_name,
        geo_id::varchar                             as geo_id,
        time_trunc::varchar                         as time_trunc,
        technology_id::varchar                      as technology_id,
        technology_name::varchar                    as technology_name,
        energy_group::varchar                       as energy_group,
        is_composite::boolean                       as is_composite,
        datetime_str::timestamp_ntz                 as datetime_raw,
        value_mwh::float                            as value_mwh,
        percentage::float                           as percentage
    from flattened_jason

)
 
select * from renamed_casted