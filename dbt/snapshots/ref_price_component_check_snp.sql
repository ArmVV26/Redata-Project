/*
    =======================================================================
    ref_price_component_check_snp
    -----------------------------------------------------------------------
    Snapshot de componentes de precio electronico.

    Capa: Snapshots
    Origen: ref_price_component
    Materialización: table
    Estrategia: check
    Granularidad: redata_component_id
    Clave: redata_component_id.

    Se encarga de conservar el historico de cambios del catalogo de componentes
    de precio publicado por REData.
    =======================================================================
*/

{% snapshot ref_price_component_check_snp %}

{{
    config(
        unique_key='redata_component_id',
        strategy='check',
        check_cols=[
            'component_name',
            'group_name',
            'is_composite'
        ],
        hard_deletes='invalidate'
    )
}}

select
    component_id,
    redata_component_id,
    component_name,
    group_name,
    is_composite
from {{ ref('ref_price_component') }}

{% endsnapshot %}