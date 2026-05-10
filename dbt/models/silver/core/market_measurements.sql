with

stg_market as (

    select
        request_id,
        loaded_at,
        time_trunc,
        component_name,
        datetime_raw,
        value_eur_mwh,
        percentage
    from {{ ref('stg_red_electrica__market_measurement') }}

),

ref_component as (

    select
        component_id,
        component_name
    from {{ ref('ref_price_component') }}

),

market_joined as (
    
    select
        m.request_id,
        m.loaded_at,
        c.component_id,
        m.time_trunc,
        m.datetime_raw,
        m.value_eur_mwh,
        m.percentage
    from stg_market m
    inner join ref_component c
        on m.component_name = c.component_name

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'component_id',
            'time_trunc',
            'datetime_raw'
        ]) }}                                       as market_id,
        component_id::varchar                       as component_id,
        time_trunc::varchar                         as time_trunc,
        datetime_raw::timestamp_ntz                 as datetime_ree,
        value_eur_mwh::float                        as value_eur_mwh,
        percentage::float                           as percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from market_joined
    
)

select
    market_id,
    component_id,
    time_trunc,
    datetime_ree,
    value_eur_mwh,
    percentage,
    request_id,
    loaded_at
from renamed_casted