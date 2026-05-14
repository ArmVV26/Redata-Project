{% snapshot ref_price_component_snapshot %}

{{
    config(
        target_database=env_var('DBT_ENVIRONMENTS', 'FAIL') ~ '_REDATA_SILVER',
        target_schema='snapshots',
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