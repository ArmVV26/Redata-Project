/*
    =======================================================================
    ref_technology_check_snp
    -----------------------------------------------------------------------
    Snapshot de componentes de precio electrico.

    Capa: Snapshots
    Origen: ref_technology
    Materialización: table
    Estrategia: check
    Granularidad: technology_id
    Clave: technology_id.

    Se encarga de conservar el historico de cambios del catalogo de tecnologias
    electricas construido a partir de REData.
    =======================================================================
*/

{% snapshot ref_technology_check_snp %}

{{
    config(
        target_schema='snapshots',
        unique_key='technology_id',
        strategy='check',
        check_cols=[
            'redata_technology_id',
            'technology_name',
            'energy_category_id',
            'is_composite'
        ],
        invalidate_hard_deletes=True
    )
}}

select
    technology_id,
    redata_technology_id,
    technology_name,
    energy_category_id,
    is_composite
from {{ ref('ref_technology') }}

{% endsnapshot %}