with

src_balance as (

    select
        energy_group
    from {{ ref('stg_balance_measurement') }}

),

src_generation as (

    select
        energy_group
    from {{ ref('stg_generation_measurement') }}

),

union_energy_group as (

    select 
        energy_group
    from src_balance
    union
    select
        energy_group
    from src_generation

),

renamed_casted as (

    select
        {{ dbt_utils.generate_surrogate_key(['energy_group']) }}    as energy_category_id,
        energy_group::varchar                                       as energy_category_name,
        case
            when lower(energy_group) like 'renovable' then true
            else false
        end::boolean                                                as is_renewable
    from union_energy_group

)

select
    energy_category_id,
    energy_category_name,
    is_renewable
from renamed_casted