/*
    =======================================================================
    dim_region
    -----------------------------------------------------------------------
    Dimension de regiones.

    Capa: Gold / Core
    Origen: ref_regions
    Materialización: table
    Granularidad: region_id
    Clave: region_id.

    Expone el catalogo de ambitos geograficos para analizar mediciones de 
    balance electrico por region.
    =======================================================================
*/

with

src_region as (

    select
        region_id,
        region_name,
        region_type
    from {{ ref('ref_regions') }}

)

select
    region_id,
    region_name,
    region_type
from src_region