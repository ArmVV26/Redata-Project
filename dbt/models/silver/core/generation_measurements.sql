/*
    Construye la tabla core de mediciones de generación eléctrica por tecnología
    a partir de stg_generation_measurement y la referencia de tecnología.
    Granularidad: technology_id + time_trunc + datetime_raw
    Clave: generation_id, generada a partir de technology_id, time_trunc 
    y datetime_raw.

    Mantiene la última carga disponible por medición usando loaded_at.
*/

with

stg_generation as (

    select
        request_id,
        loaded_at,
        time_trunc,
        technology_name,
        energy_group,
        datetime_raw,
        value_mwh,
        percentage
    from {{ ref('stg_red_electrica__generation_measurement') }}

),

ref_technology as (

    select
        technology_id,
        technology_name,
        energy_category_id
    from {{ ref('ref_technology') }}

),

generation_joined as (
    
    select
        g.request_id,
        g.loaded_at,
        t.technology_id,
        g.time_trunc,
        g.datetime_raw,
        g.value_mwh,
        g.percentage
    from stg_generation g
    left join {{ ref('ref_energy_category') }} e
        on g.energy_group = e.energy_category_name
    left join ref_technology t
        on g.technology_name = t.technology_name
        and e.energy_category_id = t.energy_category_id

),

generation_deduplicado as (

    select
        request_id,
        loaded_at,
        technology_id,
        time_trunc,
        datetime_raw,
        value_mwh,
        percentage,
        row_number() over(
            partition by technology_id, time_trunc, datetime_raw
            order by loaded_at desc
        ) as ranking
    from generation_joined

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'technology_id',
            'time_trunc',
            'datetime_raw'
        ]) }}                                       as generation_id,
        technology_id::varchar                      as technology_id,
        time_trunc::varchar                         as time_trunc,
        datetime_raw::timestamp_ntz                 as datetime_ree,
        value_mwh::float                            as value_mwh,
        percentage::float                           as percentage,
        request_id::varchar                         as request_id,
        loaded_at::timestamp_ntz                    as loaded_at
    from generation_deduplicado
    where ranking = 1
    
)

select
    generation_id,
    technology_id,
    time_trunc,
    datetime_ree,
    value_mwh,
    percentage,
    request_id,
    loaded_at
from renamed_casted