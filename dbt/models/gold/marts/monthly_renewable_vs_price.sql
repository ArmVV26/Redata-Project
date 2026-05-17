/*
    =======================================================================
    monthly_renewable_vs_price
    -----------------------------------------------------------------------
    Mart mensual de generacion renovable frente a precio de mercado

    Capa: Gold / Core
    Origen: fct_generation
            fct_market
            dim_technology
            dim_price_component
    Materialización: table
    Granularidad: month_start_date
    Clave: monthly_renewable_vs_price_id.

    Analiza la relacion entre el peso mensula de la generacion renovable y 
    el precio del mercado diario electrico.
    =======================================================================
*/

with 

dim_technology as (

    select
        technology_id,
        is_renewable,
        is_composite
    from {{ ref('dim_technology') }}

),

fct_generation as (

    select
        g.month_start_date,
        g.technology_id,
        g.generation_mwh,
        t.is_renewable,
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

        -- Generacion renovable mensual
        sum(
            case 
                when is_renewable then generation_mwh
                else 0
            end
        )                                               as renewable_mwh,

        -- Generacion total mensual usada como denominador
        sum(generation_mwh)                             as total_generation_mwh,

        -- Ultima carga considerada dentro del agregada
        max(loaded_at)                                  as generation_loaded_at
    from fct_generation g
    group by
        month_start_date

),

dim_price_component as (

    select
        component_id,
        component_name
    from {{ ref('dim_price_component') }}

),

fct_market as (

    select
        m.month_start_date,
        m.market_component_eur_mwh,
        m.loaded_at
    from {{ ref('fct_market') }} m
    inner join dim_price_component pc
        on m.component_id = pc.component_id
    where m.time_trunc = 'month'
        -- Se usa el componente 'Mercado diario' como referencia principal de precio
        and lower(pc.component_name) = 'mercado diario'

),

monthly_market as (

    select
        month_start_date,
        avg(market_component_eur_mwh)   as market_price_eur_mwh,
        max(loaded_at)                  as market_loaded_at
    from fct_market
    group by month_start_date

),

monthly_joined as (

    select
        g.month_start_date,
        g.renewable_mwh,
        g.total_generation_mwh,

        -- Peso renovable en ratio y porcentage
        div0(g.renewable_mwh, g.total_generation_mwh)                            as renewable_share,
        {{ to_percentage('div0(g.renewable_mwh, g.total_generation_mwh)') }}     as renewable_share_pct,

        m.market_price_eur_mwh,
        g.generation_loaded_at,
        m.market_loaded_at
    from monthly_generation g
    inner join monthly_market m
        on g.month_start_date = m.month_start_date

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'month_start_date'
        ]) }}                                                           as monthly_renewable_vs_price_id,
        month_start_date,
        renewable_mwh,
        total_generation_mwh,
        renewable_share,
        renewable_share_pct,
        market_price_eur_mwh,

        -- Variacion mensual en puntos porcentuales del peso renovable
        renewable_share_pct
            - lag(renewable_share_pct) over (
                order by month_start_date
            )                                                           as renewable_share_pct_mom_change,
        
        -- Variacion relativa mensual del precio en ratio y porcentaje
        market_price_eur_mwh
            - lag(market_price_eur_mwh) over (
                order by month_start_date
            )                                                           as market_price_eur_mwh_mom_change,
        div0(
            market_price_eur_mwh - lag(market_price_eur_mwh) over (
                order by month_start_date
            ),
            lag(market_price_eur_mwh) over (
                order by month_start_date
            )
        )                                                               as market_price_mom_change,
        {{ to_percentage(
            'div0(
                market_price_eur_mwh - lag(market_price_eur_mwh) over (
                    order by month_start_date
                ),
                lag(market_price_eur_mwh) over (
                    order by month_start_date
                )
            )'
        ) }}                                                            as market_price_mom_change_pct,
        
        generation_loaded_at,
        market_loaded_at
    from monthly_joined

)

select
    monthly_renewable_vs_price_id,
    month_start_date,
    renewable_mwh,
    total_generation_mwh,
    renewable_share,
    renewable_share_pct,
    market_price_eur_mwh,
    renewable_share_pct_mom_change,
    market_price_eur_mwh_mom_change,
    market_price_mom_change,
    market_price_mom_change_pct,
    generation_loaded_at,
    market_loaded_at
from final