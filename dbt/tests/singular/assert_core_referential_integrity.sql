with invalid_generation_technology as (

    select
        'generation_measurements' as model_name,
        'technology_id' as invalid_key,
        g.technology_id as key_value
    from {{ ref('generation_measurements') }} g
    left join {{ ref('ref_technology') }} t
        on g.technology_id = t.technology_id
    where t.technology_id is null

),

invalid_balance_technology as (

    select
        'balance_measurements' as model_name,
        'technology_id' as invalid_key,
        b.technology_id as key_value
    from {{ ref('balance_measurements') }} b
    left join {{ ref('ref_technology') }} t
        on b.technology_id = t.technology_id
    where t.technology_id is null

),

invalid_balance_region as (

    select
        'balance_measurements' as model_name,
        'region_id' as invalid_key,
        b.region_id as key_value
    from {{ ref('balance_measurements') }} b
    left join {{ ref('ref_regions') }} r
        on b.region_id = r.region_id
    where r.region_id is null

),

invalid_market_component as (

    select
        'market_measurements' as model_name,
        'component_id' as invalid_key,
        m.component_id as key_value
    from {{ ref('market_measurements') }} m
    left join {{ ref('ref_price_component') }} c
        on m.component_id = c.component_id
    where c.component_id is null

)

select *
from invalid_generation_technology

union all

select *
from invalid_balance_technology

union all

select *
from invalid_balance_region

union all

select *
from invalid_market_component