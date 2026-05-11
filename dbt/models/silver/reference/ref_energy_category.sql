/*
    Construye la tabla de referencia de categorías energéticas a partir de los
    grupos energéticos presentes en los modelos staging balance y generation.
    Granularidad: energy_category_name
    Clave: energy_category_id, generada a partir de energy_category_name. 
*/

with

src_balance as (

    select
        energy_group
    from {{ ref('stg_red_electrica__balance_measurement') }}

),

src_generation as (

    select
        energy_group
    from {{ ref('stg_red_electrica__generation_measurement') }}

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
            when lower(trim(energy_group)) = 'renovable' then true
            else false
        end::boolean                                                as is_renewable
    from union_energy_group

)

select
    energy_category_id,
    energy_category_name,
    is_renewable
from renamed_casted