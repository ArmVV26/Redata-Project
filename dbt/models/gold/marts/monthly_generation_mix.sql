/*
    =======================================================================
    monthly_generation_mix
    -----------------------------------------------------------------------
    Mart mensual de mix de generacion electrica

    Capa: Gold / Core
    Origen: fct_generation
            dim_technology
    Materialización: table
    Granularidad: month_start_date + technology_id
    Clave: monthly_generation_mix_id.

    Calcula el peso mensual de cada tecnologia dentro del total de generacion
    electrica, evitando doble conteo de tecnologias compuestas.
    =======================================================================
*/

with

dim_technology as (

    select
        technology_id,
        is_composite
    from {{ ref('dim_technology') }}

),

fct_generation as (

    select
        g.month_start_date,
        g.technology_id,
        g.generation_mwh,
        g.loaded_at
    from {{ ref('fct_generation') }} g
    inner join dim_technology t
        on g.technology_id = t.technology_id
    where g.time_trunc = 'month'

        -- Se excluyen tecnologias compuestas para evitar doble conteo en los agregados
        and t.is_composite = false

),

monthly_generation as (

    select
        month_start_date,
        technology_id,

        -- Generacion mensual por tecnologia
        sum(generation_mwh)     as generation_mwh,

        -- Ultima carga considerada dentro del agregada
        max(loaded_at)          as loaded_at
        from fct_generation
        group by
            month_start_date,
            technology_id
),

monthly_total_generation as (

    select
        month_start_date,

        -- Calculo el peso de cada tecnologia por mes
        sum(generation_mwh)     as total_generation_mwh
    from monthly_generation
    group by 
        month_start_date

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'g.month_start_date',
            'g.technology_id'
        ]) }}                                                                   as monthly_generation_mix_id,
        g.month_start_date,
        g.technology_id,
        g.generation_mwh,
        t.total_generation_mwh,

        -- Participacion de la tecnologia dentro del mix mensual
        div0(g.generation_mwh, t.total_generation_mwh)                          as generation_share,
        {{ to_percentage('div0(g.generation_mwh, t.total_generation_mwh)') }}   as generation_share_pct,
        
        g.loaded_at
    from monthly_generation g
    inner join monthly_total_generation t
        on g.month_start_date = t.month_start_date

)

select
    monthly_generation_mix_id,
    month_start_date,
    technology_id,
    generation_mwh,
    total_generation_mwh,
    generation_share,
    generation_share_pct,
    loaded_at
from final