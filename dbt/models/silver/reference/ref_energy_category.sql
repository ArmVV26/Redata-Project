/*
    =======================================================================
    ref_energy_category
    -----------------------------------------------------------------------
    Modelo de referencia de categorias energeticas.

    Capa: Silver / Reference
    Origen: stg_red_electrica__balance_measurement
            stg_red_electrica__generation_measurement
    Materialización: table
    Granularidad: energy_category_name
    Clave: energy_category_id, generada a partir de energy_category_name. 

    Unifica los grupos energeticos presentes en balance y generacion para 
    construir una referencia comun reutilizable por las dimensiones y hechos.
    =======================================================================
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

    -- Union que elimina duplicados entre los grupos presentes en balance y generacion
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
        {{ dbt_utils.generate_surrogate_key(['energy_group']) }}        as energy_category_id,
        energy_group::varchar                                           as energy_category_name,

        -- Flag analitico usado posteriormente para separar generacion renovable y no renovables
        case
            when lower(trim(energy_group)) = 'renovable' then true
            else false
        end::boolean                                                    as is_renewable
    from union_energy_group

)

select
    energy_category_id,
    energy_category_name,
    is_renewable
from renamed_casted