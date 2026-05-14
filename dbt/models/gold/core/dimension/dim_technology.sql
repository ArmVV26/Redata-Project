with

src_technology as (

    select
        technology_id,
        redata_technology_id,
        technology_name,
        energy_category_id,
        is_composite
    from {{ ref('ref_technology') }}

),

src_energy_category as (

    select
        energy_category_id,
        energy_category_name,
        is_renewable
    from {{ ref('ref_energy_category') }}

),

renamed_casted as (

    select
        t.technology_id::varchar                as technology_id,
        t.technology_name::varchar              as technology_name,
        t.redata_technology_id::varchar         as redata_technology_id,
        e.energy_category_name::varchar         as energy_category_name,
        e.is_renewable::boolean                 as is_renewable,
        t.is_composite::boolean                 as is_composite
    from src_technology t
    inner join src_energy_category e
        on t.energy_category_id = e.energy_category_id

)

select
    technology_id,
    technology_name,
    redata_technology_id,
    energy_category_name,
    is_renewable,
    is_composite
from renamed_casted