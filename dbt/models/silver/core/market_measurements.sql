{{
    config(
        materialized='incremental',
        unique_key='market_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

/*
    =======================================================================
    market_measurements
    -----------------------------------------------------------------------
    Modelo core de mediciones de mercado electrico.

    Capa: Silver / Core
    Origen: stg_red_electrica__market_measurement
            ref_price_component
    Materialización: incremental
    Estrategia incremental: merge
    Granularidad: component_id + time_trunc + datetime_ree
    Clave: market_id, generada a partir de component_id, time_trunc 
    y datetime_ree.

    Relaciona las mediciones de mercado con su componente de precio analitico,
    elimina duplicados de carga y conserva la ultima version disponible.
    =======================================================================
*/

with

stg_market as (

    select
        request_id,
        loaded_at,
        time_trunc,
        component_name,
        group_name,
        datetime_ree,
        value_eur_mwh,
        source_percentage
    from {{ ref('stg_red_electrica__market_measurement') }}

    {% if is_incremental() %}
        -- En ejecuciones incrementales solo procesa cargas nuevas o actualizadas
        where loaded_at >= (
            select coalesce(max(loaded_at), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

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
        m.datetime_ree,
        m.value_eur_mwh,
        m.source_percentage
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
        datetime_ree,
        value_eur_mwh,
        source_percentage,

        -- Ranking usado para conservar la ultima carga disponible por medicion
        {{ deduplicate_by_latest(
            partition_by=[
                'component_id',
                'time_trunc',
                'datetime_ree'
            ],
            order_by=[
                'loaded_at',
                'request_id'
            ]
        ) }} as ranking
    from market_joined

),

final as (

    select
        -- Clave surrogate estable para analisis, independiente del endpoint de origen
        {{ dbt_utils.generate_surrogate_key([
            'component_id',
            'time_trunc',
            'datetime_ree'
        ]) }}                               as market_id,
        component_id,
        time_trunc,
        datetime_ree,
        value_eur_mwh,
        source_percentage,
        request_id,
        loaded_at
    from market_deduplicado
    where ranking = 1
        -- Se descartan mediciones que no hayan podido mapearse contra la referencia
        and component_id is not null
    
)

select
    market_id,
    component_id,
    time_trunc,
    datetime_ree,
    value_eur_mwh,
    source_percentage,
    request_id,
    loaded_at
from final