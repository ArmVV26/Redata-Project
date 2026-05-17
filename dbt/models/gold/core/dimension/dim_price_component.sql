/*
    =======================================================================
    dim_price_component
    -----------------------------------------------------------------------
    Dimension de componentes de precio electrico.

    Capa: Gold / Core
    Origen: ref_price_component_check_snp
    Materialización: table
    Granularidad: component_id
    Clave: component_id.

    Expone la version vigente del catalogo de componentes de precio para su 
    uso en los hechos, marts y herramientas de visualizacion.
    =======================================================================
*/

with

src_price_component as (

    select
        component_id,
        redata_component_id,
        component_name,
        group_name,
        is_composite
    from {{ ref('ref_price_component_check_snp') }}
    where dbt_valid_to is null

)

select
    component_id,
    redata_component_id,
    component_name,
    group_name,
    is_composite
from src_price_component