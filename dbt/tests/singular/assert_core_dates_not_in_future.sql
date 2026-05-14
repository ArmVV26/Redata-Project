with invalid_generation as (

    select
        'generation_measurements' as model_name,
        generation_id as record_id,
        datetime_ree,
        loaded_at
    from {{ ref('generation_measurements') }}
    where datetime_ree > current_timestamp()
       or loaded_at > current_timestamp()

),

invalid_balance as (

    select
        'balance_measurements' as model_name,
        balance_id as record_id,
        datetime_ree,
        loaded_at
    from {{ ref('balance_measurements') }}
    where datetime_ree > current_timestamp()
       or loaded_at > current_timestamp()

),

invalid_market as (

    select
        'market_measurements' as model_name,
        market_id as record_id,
        datetime_ree,
        loaded_at
    from {{ ref('market_measurements') }}
    where datetime_ree > current_timestamp()
       or loaded_at > current_timestamp()

)

select *
from invalid_generation

union all

select *
from invalid_balance

union all

select *
from invalid_market