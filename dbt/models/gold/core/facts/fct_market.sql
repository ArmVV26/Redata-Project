/*
    =======================================================================
    fct_market
    -----------------------------------------------------------------------
    Fact de mediciones de mercado electrico

    Capa: Gold / Core
    Origen: market_measurements
            dim_date
            dim_price_component
    Materialización: table
    Granularidad: market_id
    Clave: market_id.

    Expone las mediciones de componentes del precio electrico listas para
    analisis, relacionandolas con sus dimensiones de fecha y componente.
    =======================================================================
*/

with

src_market as (

    select
        market_id,
        component_id,
        time_trunc,

        -- Claves temporales derivadas para facilitar joins y analisis mensual
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

        -- Metrica original y version expresada en procentaje
        m.source_percentage::float                          as market_share,
        {{ to_percentage('m.source_percentage') }}          as market_share_pct,

        -- Campos de trazabilidad de la medicion cargada
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