/*
    =======================================================================
    fct_generation
    -----------------------------------------------------------------------
    Fact de mediciones de generacion electrica.

    Capa: Gold / Core
    Origen: generation_measurements
            dim_date
            dim_technology
    Materialización: table
    Granularidad: generation_id
    Clave: generation_id.

    Expone las mediciones de generacion electrica por tecnologia y fecha,
    preparadas para analisis y consumo desde marts o herramientas de visualizacion.
    =======================================================================
*/

with

src_generation as (

    select
        generation_id,
        technology_id,
        time_trunc,
        
        -- Claves temporales derivadas para facilitar joins y analisis mensual
        datetime_ree,
        datetime_ree::date                          as date_id,
        date_trunc('month', datetime_ree)::date     as month_start_date,

        value_mwh,
        source_percentage,
        request_id,
        loaded_at
    from {{ ref('generation_measurements') }}

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

final as (

    select
        g.generation_id,
        d.date_id,
        g.month_start_date,
        t.technology_id,
        g.time_trunc,
        g.datetime_ree,
        g.value_mwh                                     as generation_mwh,

        -- Metrica original y version expresada en porcentaje
        g.source_percentage                             as generation_share,
        {{ to_percentage('g.source_percentage') }}      as generation_share_pct,

        -- Campos de trazabilidad de la medicion cargada
        g.request_id,
        g.loaded_at
    from src_generation g
    inner join dim_date d
        on g.date_id = d.date_id
    inner join dim_technology t
        on g.technology_id = t.technology_id

)

select
    generation_id,
    date_id,
    month_start_date,
    technology_id,
    time_trunc,
    datetime_ree,
    generation_mwh,
    generation_share,
    generation_share_pct,
    request_id,
    loaded_at
from final