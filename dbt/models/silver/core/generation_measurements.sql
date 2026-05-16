{{
    config(
        materialized='incremental',
        unique_key='generation_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

/*
    Construye la tabla core de mediciones de generación eléctrica por tecnología
    a partir de stg_generation_measurement y la referencia de tecnología.
    Granularidad: technology_id + time_trunc + datetime_ree
    Clave: generation_id, generada a partir de technology_id, time_trunc 
    y datetime_ree.

    Mantiene la última carga disponible por medición usando loaded_at.
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
        on g.energy_group = e.energy_category_name
    left join ref_technology t
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

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'time_trunc',
            'datetime_ree'
        ]) }}                                       as generation_id,
        technology_id::varchar                      as technology_id,
        time_trunc::varchar                         as time_trunc,
        datetime_ree::timestamp_ntz                 as datetime_ree,
        value_mwh::float                            as value_mwh,
        source_percentage::float                    as source_percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from generation_deduplicado
    where ranking = 1
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
from renamed_casted