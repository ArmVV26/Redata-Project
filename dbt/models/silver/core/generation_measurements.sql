with

stg_balance as (

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

balance_joined as (
    
    select
        b.request_id,
        b.loaded_at,
        t.technology_id,
        b.time_trunc,
        b.datetime_raw,
        b.value_mwh,
        b.percentage
    from stg_balance b
    inner join ref_technology t
        on b.technology_name = t.technology_name

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'time_trunc',
            'datetime_raw'
        ]) }}                                       as balance_id,
        technology_id::varchar                      as technology_id,
        time_trunc::varchar                         as time_trunc,
        datetime_raw::timestamp_ntz                 as datetime_ree,
        value_mwh::float                            as value_mwh,
        percentage::float                           as percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from balance_joined
    
)

select
    balance_id,
    technology_id,
    time_trunc,
    datetime_ree,
    value_mwh,
    percentage,
    request_id,
    loaded_at
from renamed_casted