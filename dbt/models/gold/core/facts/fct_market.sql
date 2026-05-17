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
        request_id,
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

final as (

    select
        m.market_id,
        d.date_id,
        m.month_start_date,
        pm.component_id,
        m.time_trunc,
        m.datetime_ree,
        m.value_eur_mwh                                     as market_component_eur_mwh,
        m.source_percentage::float                          as market_share,
        {{ to_percentage('m.source_percentage') }}          as market_share_pct,
        m.request_id,
        m.loaded_at
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
    market_component_eur_mwh,
    market_share,
    market_share_pct,
    request_id,
    loaded_at
from final