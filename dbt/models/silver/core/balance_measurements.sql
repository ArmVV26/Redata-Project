{{
    config(
        materialized='incremental',
        unique_key='balance_id',
        incremental_strategy='merge',
        on_schema_change='fail'
    )
}}

/*
    Construye la tabla core de mediciones de balance eléctrico a partir de
    stg_balance_measurement y las referencias de tecnología y región.
    Granularidad: technology_id + region_id + time_trunc + datetime_ree
    Clave: balance_id, generada a partir de technology_id, region_id, 
    time_trunc y datetime_ree.

    Mantiene la última carga disponible por medición usando loaded_at.
*/

with

stg_balance as (

    select
        request_id,
        loaded_at,
        geo_id,
        time_trunc,
        technology_name,
        datetime_ree,
        value_mwh,
        source_percentage
    from {{ ref('stg_red_electrica__balance_measurement') }}

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
        technology_name
    from {{ ref('ref_technology') }}

),

ref_regions as (

    select
        region_id,
        region_name
    from {{ ref('ref_regions') }}

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
    left join ref_technology t
        on b.technology_name = t.technology_name
    left join ref_regions r
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

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'region_id',
            'time_trunc',
            'datetime_ree'
        ]) }}                                       as balance_id,
        technology_id::varchar                      as technology_id,
        region_id::integer                          as region_id,
        time_trunc::varchar                         as time_trunc,
        datetime_ree::timestamp_ntz                 as datetime_ree,
        value_mwh::float                            as value_mwh,
        source_percentage::float                    as source_percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from balance_deduplicado
    where ranking = 1
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
from renamed_casted