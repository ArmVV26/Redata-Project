/*
    =======================================================================
    monthly_balance_region
    -----------------------------------------------------------------------
    Mart mensual de balance electrico por region y tecnologia

    Capa: Gold / Core
    Origen: fct_balance
            dim_technology
    Materialización: table
    Granularidad: month_start_date + region_id + technology_id
    Clave: monthly_balance_region_id.

    Calcula el balance electrico mensual por region y tecnologia, junto con
    el peso de cada tecnologia dentro del total regional mensual.
    =======================================================================
*/

with

dim_technology as (

    select
        technology_id,
        is_composite
    from {{ ref('dim_technology') }}

),

fct_balance as (

    select
        b.month_start_date,
        b.region_id,
        b.technology_id,
        b.balance_mwh,
        b.loaded_at
    from {{ ref('fct_balance') }} b
    inner join dim_technology t
        on b.technology_id = t.technology_id
    where b.time_trunc = 'month'

        -- Se excluyen tecnologias compuestas para evitar doble conteo en los agregados
        and t.is_composite = false

),

monthly_balance as (

    select
        month_start_date,
        region_id,
        technology_id,

        -- Balance mensual por region y tecnologia
        sum(balance_mwh)        as balance_mwh,

        -- Ultima carga considerada dentro del agregada
        max(loaded_at)          as loaded_at
    from fct_balance
    group by
        month_start_date,
        region_id,
        technology_id

),

monthly_region_total_balance as (

    select
        month_start_date,
        region_id,

        -- Total mensual regional usado denominador
        sum(balance_mwh)        as total_region_balance_mwh
    from monthly_balance
    group by
        month_start_date,
        region_id

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'b.month_start_date',
            'b.region_id',
            'b.technology_id'
        ]) }}                                                                       as monthly_balance_region_id,
        b.month_start_date,
        b.region_id,
        b.technology_id,
        b.balance_mwh,
        t.total_region_balance_mwh,

        -- Peso de cada tecnologia dentro del balance mesnual de la region
        div0(b.balance_mwh, t.total_region_balance_mwh)                             as region_balance_share,
        {{ to_percentage('div0(b.balance_mwh, t.total_region_balance_mwh)') }}      as region_balance_share_pct,
        
        b.loaded_at
    from monthly_balance b
    inner join monthly_region_total_balance t
        on b.month_start_date = t.month_start_date
        and b.region_id = t.region_id

)

select
    monthly_balance_region_id,
    month_start_date,
    region_id,
    technology_id,
    balance_mwh,
    total_region_balance_mwh,
    region_balance_share,
    region_balance_share_pct,
    loaded_at
from final