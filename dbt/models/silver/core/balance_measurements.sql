{{
    config(
        materialized='incremental',
        unique_key='balance_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

/*
    =======================================================================
    balance_measurements
    -----------------------------------------------------------------------
    Modelo core de mediciones de balance electrico.

    Capa: Silver / Core
    Origen: stg_red_electrica__balance_measurement
            ref_technology
            ref_energy_category
            ref_regions
    Materialización: incremental
    Estrategia incremental: merge
    Granularidad: technology_id + region_id + time_trunc + datetime_ree
    Clave: balance_id, generada a partir de technology_id, region_id, 
    time_trunc y datetime_ree.

    Normaliza las mediciones de balance electrico relacionandolas con una
    tecnologia y una region analitica, manteniendo una unica version
    vigente por medicion.
    =======================================================================
*/

with

stg_balance as (

    select
        request_id,
        loaded_at,
        geo_id,
        time_trunc,
        redata_technology_id,
        technology_name,
        energy_group,
        datetime_ree,
        value_mwh,
        source_percentage
    from {{ ref('stg_red_electrica__balance_measurement') }}

    {% if is_incremental() %}
        -- En ejecuciones incrementales solo procesa cargas nuevas o actualizadas
        where loaded_at >= (
            select coalesce(max(loaded_at), '1900-01-01'::timestamp_ntz)
            from {{ this }}
        )
    {% endif %}

),

ref_technology as (

    select
        technology_id,
        redata_technology_id,
        technology_name,
        energy_category_id
    from {{ ref('ref_technology') }}

),

ref_regions as (

    select
        region_id,
        region_name
    from {{ ref('ref_regions') }}

),

ref_energy_category as (

    select
        energy_category_id,
        energy_category_name
    from {{ ref('ref_energy_category') }}

),

balance_joined as (
    
    select
        b.request_id,
        b.loaded_at,
        t.technology_id,
        r.region_id,
        b.time_trunc,
        b.datetime_ree,
        b.value_mwh,
        b.source_percentage
    from stg_balance b
    left join ref_energy_category e
        -- Primero se resuelve la categoria energetica para poder usarla en la clave de tecnologia
        on b.energy_group = e.energy_category_name
    left join ref_technology t
        -- La tecnologia se verifica usando nombre, categoria y redata_technology_id
        -- Se contempla el caso de identificadores nulos para no perder tecnologias validas
        on b.technology_name = t.technology_name
        and e.energy_category_id = t.energy_category_id
        and ( 
                b.redata_technology_id = t.redata_technology_id 
                or (
                    b.redata_technology_id is null
                    and t.redata_technology_id is null
                )
            )
    left join ref_regions r
        -- Relaciona el geo_id original con la referencia geografica normalizada
        on b.geo_id = r.region_id

),

balance_deduplicado as (

    select
        request_id,
        loaded_at,
        technology_id,
        region_id,
        time_trunc,
        datetime_ree,
        value_mwh,
        source_percentage,

        -- Ranking usado para conservar la ultima carga disponible por medicion
        {{ deduplicate_by_latest(
            partition_by=[
                'technology_id',
                'region_id',
                'time_trunc',
                'datetime_ree'
            ],
            order_by=[
                'loaded_at',
                'request_id'
            ]
        ) }} as ranking
    from balance_joined

),

final as (

    select
        -- Clave surrogate estable para analisis, independiente del endpoint de origen
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'region_id',
            'time_trunc',
            'datetime_ree'
        ]) }}                               as balance_id,
        technology_id,
        region_id,
        time_trunc,
        datetime_ree,
        value_mwh,
        source_percentage,
        request_id,
        loaded_at
    from balance_deduplicado
    where ranking = 1
        -- Se descartan mediciones que no hayan podido mapearse contra las referencias
        and technology_id is not null
        and region_id is not null
    
)

select
    balance_id,
    technology_id,
    region_id,
    time_trunc,
    datetime_ree,
    value_mwh,
    source_percentage,
    request_id,
    loaded_at
from final