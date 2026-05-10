with

stg_generation as (

    select
        request_id,
        loaded_at,
        time_trunc,
        technology_name,
        datetime_raw,
        value_mwh,
        percentage
    from {{ ref('stg_red_electrica__generation_measurement') }}

),

ref_technology as (

    select
        technology_id,
        technology_name
    from {{ ref('ref_technology') }}

),

generation_joined as (
    
    select
        g.request_id,
        g.loaded_at,
        t.technology_id,
        g.time_trunc,
        g.datetime_raw,
        g.value_mwh,
        g.percentage
    from stg_generation g
    inner join ref_technology t
        on g.technology_name = t.technology_name

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'time_trunc',
            'datetime_raw'
        ]) }}                                       as generation_id,
        technology_id::varchar                      as technology_id,
        time_trunc::varchar                         as time_trunc,
        datetime_raw::timestamp_ntz                 as datetime_ree,
        value_mwh::float                            as value_mwh,
        percentage::float                           as percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from generation_joined
    
)

select
    generation_id,
    technology_id,
    time_trunc,
    datetime_ree,
    value_mwh,
    percentage,
    request_id,
    loaded_at
from renamed_casted