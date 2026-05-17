/*
    =======================================================================
    ref_technology
    -----------------------------------------------------------------------
    Modelo de referencia de tecnologias electricas.

    Capa: Silver / Reference
    Origen: stg_red_electrica__balance_measurement
            stg_red_electrica__generation_measurement
    Materialización: table
    Granularidad: technology_name + energy_category_id
    Clave: technology_id, generada a partir de technology_name y energy_category_id.

    Construye un catalogo comun de tecnologias electricas a partir de los 
    endpoints de balance y generacion, resolviendo diferencias entre los 
    identificadores originales de REData.
    =======================================================================
*/

with

src_balance as (

    select
        redata_technology_id,
        technology_name,
        energy_group,
        is_composite
    from {{ ref('stg_red_electrica__balance_measurement') }}

),

src_generation as (

    select
        redata_technology_id,
        technology_name,
        energy_group,
        is_composite
    from {{ ref('stg_red_electrica__generation_measurement') }}

),

union_technology as (

    -- Unifica las tecnologias detectadas en balance y generacion
    select
        redata_technology_id,
        technology_name,
        energy_group,
        is_composite
    from src_balance
    union
    select
        redata_technology_id,
        technology_name,
        energy_group,
        is_composite
    from src_generation

),

technology_deduplicado as (

    -- Deduplia tecnologias equivalentes por nombre, grupo energetico y flag composite
    -- En caso de igualdad, se conserva la tecnologia con menor referencia informativa
    select
        technology_name,
        energy_group,
        is_composite,
        min(redata_technology_id) as redata_technology_id
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
        -- Clave surrogate estable para analisis, independiente del endpoint de origen
        {{ dbt_utils.generate_surrogate_key([
            't.technology_name',
            'e.energy_category_id'
        ]) }}                                           as technology_id,
        t.redata_technology_id::integer                 as redata_technology_id,
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