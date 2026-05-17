with

src_technology as (

    select
        technology_id,
        redata_technology_id,
        technology_name,
        energy_category_id,
        is_composite
    from {{ ref('ref_technology_check_snp') }}
    where dbt_valid_to is null

),

src_energy_category as (

    select
        energy_category_id,
        energy_category_name,
        is_renewable
    from {{ ref('ref_energy_category') }}

),

final as (

    select
        t.technology_id,
        t.technology_name,
        t.redata_technology_id,
        e.energy_category_name,
        e.is_renewable,
        t.is_composite
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
from final