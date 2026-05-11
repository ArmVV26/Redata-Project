/*
    Construye la tabla de referencia de tecnologías eléctricas a partir de las
    tecnologías presentes en los modelos staging balance y generation.
    Granularidad: technology_name + energy_category_id
    Clave: technology_id, generada a partir de technology_name y energy_category_id. 
*/

with

src_balance as (

    select
        technology_id,
        technology_name,
        energy_group,
        is_composite
    from {{ ref('stg_red_electrica__balance_measurement') }}

),

src_generation as (

    select
        technology_id,
        technology_name,
        energy_group,
        is_composite
    from {{ ref('stg_red_electrica__generation_measurement') }}

),

union_technology as (

    select
        technology_id,
        technology_name,
        energy_group,
        is_composite
    from src_balance
    union
    select
        technology_id,
        technology_name,
        energy_group,
        is_composite
    from src_generation

),

technology_deduplicado as (

    select
        technology_name,
        energy_group,
        is_composite,
        min(technology_id)      as technology_id
    from union_technology
    group by
        technology_name,
        energy_group,
        is_composite

),

energy_category as (

    select
        energy_category_id,
        energy_category_name
    from {{ ref('ref_energy_category') }}

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key([
            't.technology_name',
            'e.energy_category_id'
        ]) }}                                           as technology_id,
        t.technology_id::varchar                        as redata_technology_id,
        t.technology_name::varchar                      as technology_name,
        e.energy_category_id::varchar                   as energy_category_id,
        t.is_composite::boolean                         as is_composite
    from technology_deduplicado t
    inner join energy_category e
        on t.energy_group = e.energy_category_name

)

select
    technology_id,
    redata_technology_id,
    technology_name,
    energy_category_id,
    is_composite
from renamed_casted