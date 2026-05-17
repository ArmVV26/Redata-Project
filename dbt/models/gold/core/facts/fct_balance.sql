/*
    =======================================================================
    fct_balance
    -----------------------------------------------------------------------
    Fact de mediciones de balance electrico

    Capa: Gold / Core
    Origen: balance_measurements
            dim_date
            dim_technology
            dim_region
    Materialización: table
    Granularidad: balance_id
    Clave: balance_id.

    Expone las mediciones de balance electrico por region, tecnologia y fecha,
    lista para analisis y consumo desde marts o herramientas de visualizacion.
    =======================================================================
*/

with

src_balance as (

    select
        balance_id,
        technology_id,
        region_id,
        time_trunc,

        -- Claves temporales derivadas para facilitar joins y analisis mensual
        datetime_ree,
        datetime_ree::date                          as date_id,
        date_trunc('month', datetime_ree)::date     as month_start_date,

        value_mwh,
        source_percentage,
        request_id,
        loaded_at
    from {{ ref('balance_measurements') }}

),

dim_date as (

    select
        date_id
    from {{ ref('dim_date') }}

),

dim_technology as (

    select
        technology_id
    from {{ ref('dim_technology') }}

),

dim_region as (

    select
        region_id
    from {{ ref('dim_region') }}

),

final as (

    select
        b.balance_id,
        d.date_id,
        b.month_start_date,
        r.region_id,
        t.technology_id,
        b.time_trunc,
        b.datetime_ree,
        b.value_mwh                                     as balance_mwh,

        -- Metrica original y version expresada en procentaje
        b.source_percentage::float                      as balance_share,
        {{ to_percentage('b.source_percentage') }}      as balance_share_pct,

        -- Campos de trazabilidad de la medicion cargada
        b.request_id,
        b.loaded_at
    from src_balance b
    inner join dim_date d
        on b.date_id = d.date_id
    inner join dim_technology t
        on b.technology_id = t.technology_id
    inner join dim_region r
        on b.region_id = r.region_id

)

select
    balance_id,
    date_id,
    month_start_date,
    region_id,
    technology_id,
    time_trunc,
    datetime_ree,
    balance_mwh,
    balance_share,
    balance_share_pct,
    request_id,
    loaded_at
from final