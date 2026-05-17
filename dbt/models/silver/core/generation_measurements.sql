{{
    config(
        materialized='incremental',
        unique_key='generation_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

/*
    =======================================================================
    generation_measurements
    -----------------------------------------------------------------------
    Modelo core de mediciones de generacion electrica.

    Capa: Silver / Core
    Origen: stg_red_electrica__generation_measurement
            ref_technology
            ref_energy_category
    Materialización: incremental
    Estrategia incremental: merge
    Granularidad: technology_id + time_trunc + datetime_ree
    Clave: generation_id, generada a partir de technology_id, time_trunc 
    y datetime_ree.

    Convierte las mediciones de generacion de REData en una tabla analitica
    estable, asociado cada registro a una tecnologia normalizada.
    =======================================================================
*/

with

stg_generation as (

    select
        request_id,
        loaded_at,
        time_trunc,
        redata_technology_id,
        technology_name,
        energy_group,
        datetime_ree,
        value_mwh,
        source_percentage
    from {{ ref('stg_red_electrica__generation_measurement') }}

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

ref_energy_category as (

    select
        energy_category_id,
        energy_category_name
    from {{ ref('ref_energy_category') }}

),

generation_joined as (
    
    select
        g.request_id,
        g.loaded_at,
        t.technology_id,
        g.time_trunc,
        g.datetime_ree,
        g.value_mwh,
        g.source_percentage
    from stg_generation g
    left join ref_energy_category e
        -- Primero se resuelve la categoria energetica para poder usarla en la clave de tecnologia
        on g.energy_group = e.energy_category_name
    left join ref_technology t
        -- La tecnologia se verifica usando nombre, categoria y redata_technology_id
        -- Se contempla el caso de identificadores nulos para no perder tecnologias validas
        on g.technology_name = t.technology_name
        and e.energy_category_id = t.energy_category_id
        and ( 
                g.redata_technology_id = t.redata_technology_id 
                or (
                    g.redata_technology_id is null
                    and t.redata_technology_id is null
                )
            )

),

generation_deduplicado as (

    select
        request_id,
        loaded_at,
        technology_id,
        time_trunc,
        datetime_ree,
        value_mwh,
        source_percentage,

        -- Ranking usado para conservar la ultima carga disponible por medicion
        {{ deduplicate_by_latest(
            partition_by=[
                'technology_id',
                'time_trunc',
                'datetime_ree'
            ],
            order_by=[
                'loaded_at',
                'request_id'
            ]
        ) }} as ranking
    from generation_joined

),

final as (

    select
        -- Clave surrogate estable para analisis, independiente del endpoint de origen
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'time_trunc',
            'datetime_ree'
        ]) }}                               as generation_id,
        technology_id,
        time_trunc,
        datetime_ree,
        value_mwh,
        source_percentage,
        request_id,
        loaded_at
    from generation_deduplicado
    where ranking = 
        -- Se descartan mediciones que no hayan podido mapearse contra la referencia
        and technology_id is not null
    
)

select
    generation_id,
    technology_id,
    time_trunc,
    datetime_ree,
    value_mwh,
    source_percentage,
    request_id,
    loaded_at
from final