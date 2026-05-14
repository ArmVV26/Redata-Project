/*
    Snapshot de componentes de precio de REData.
    Detecta cambios en el nombre, grupo o flag de componente compuesto.
    Granularidad: redata_component_id
    Clave: redata_component_id
*/

{% snapshot ref_price_component_snapshot %}

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