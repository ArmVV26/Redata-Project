with

src_market as (

    select
        market_id,
        component_id,
        time_trunc,
        datetime_ree,
        datetime_ree::date                          as date_id,
        date_trunc('month', datetime_ree)::date     as month_start_date,
        value_eur_mwh,
        source_percentage,
        loaded_at
    from {{ ref('market_measurements') }}

),

dim_date as (

    select
        date_id
    from {{ ref('dim_date') }}

),

dim_price_component as (

    select
        component_id
    from {{ ref('dim_price_component') }}

),

renamed_casted as (

    select
        m.market_id::varchar                        as market_id,
        d.date_id::date                             as date_id,
        m.month_start_date::date                    as month_start_date,
        pm.component_id::varchar                    as component_id,
        m.time_trunc::varchar                       as time_trunc,
        m.datetime_ree::timestamp_ntz               as datetime_ree,
        m.value_eur_mwh::float                      as market_eur_mwh,
        m.source_percentage::float                  as market_percentage,
        m.loaded_at::timestamp_ntz                  as loaded_at
    from src_market m
    inner join dim_date d
        on m.date_id = d.date_id
    inner join dim_price_component pm
        on m.component_id = pm.component_id

)

select
    market_id,
    date_id,
    month_start_date,
    component_id,
    time_trunc,
    datetime_ree,
    market_eur_mwh,
    market_percentage,
    loaded_at
from renamed_casted