/*
    Construye la tabla core de mediciones de componentes del precio de la 
    electricidad a partir de stg_market_measurement y la referencia de price_component.
    Granularidad: component_id + time_trunc + datetime_raw
    Clave: market_id, generada a partir de component_id, time_trunc 
    y datetime_raw.

    Mantiene la última carga disponible por medición usando loaded_at.
*/

with

stg_market as (

    select
        request_id,
        loaded_at,
        time_trunc,
        component_name,
        group_name,
        datetime_raw,
        value_eur_mwh,
        percentage
    from {{ ref('stg_red_electrica__market_measurement') }}

),

ref_price_component as (

    select
        component_id,
        component_name,
        group_name
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
    left join ref_price_component c
        on m.component_name = c.component_name
        and m.group_name = c.group_name

),

market_deduplicado as (

    select
        request_id,
        loaded_at,
        component_id,
        time_trunc,
        datetime_raw,
        value_eur_mwh,
        percentage,
        row_number() over(
            partition by component_id, time_trunc, datetime_raw
            order by loaded_at desc
        ) as ranking
    from market_joined

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
    from market_deduplicado
    where ranking = 1
    
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