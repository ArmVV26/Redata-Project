{% snapshot ref_technology_check_snp %}

{{
    config(
        target_database=env_var('DBT_ENVIRONMENTS', 'FAIL') ~ '_REDATA_SILVER',
        target_schema='snapshots',
        unique_key='redata_technology_id',
        strategy='check',
        check_cols=[
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