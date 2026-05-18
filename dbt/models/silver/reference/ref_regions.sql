/*
    =======================================================================
    ref_regions
    -----------------------------------------------------------------------
    Modelo de referencia de regiones REData.

    Capa: Silver / Reference
    Origen: seed regions
    Materialización: table
    Granularidad: region_name
    Clave: region_id, equivalente al geo_id original. 

    Normaliza el catalogo de ambitos geograficos para poder relacionar las 
    mediciones de balance con una dimension geografica estable.
    =======================================================================
*/

with

src_regions as (

    select
        geo_id,
        geo_name,
        geo_type
    from {{ ref('regions') }}

),

renamed_casted as (

    select
        -- Se conserva geo_id como clave natural de region
        geo_id::integer             as region_id,
        trim(geo_name)::varchar     as region_name,
        geo_type::varchar           as region_type
    from src_regions

)

select
    region_id,
    region_name,
    region_type
from renamed_casted