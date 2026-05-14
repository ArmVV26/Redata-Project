with

src_balance as (

    select
        balance_id,
        technology_id,
        region_id,
        time_trunc,
        period_start_date,
        value_mwh,
        source_percentage,
        loaded_at
    from {{ ref('balance_measurements') }}

),

renamed_casted as (

    select
        balance_id::varchar                       as balance_id,
        period_start_date::date                   as date_id,
        region_id::varchar                        as region_id,
        technology_id::varchar                    as technology_id,
        time_trunc::varchar                       as time_trunc,
        value_mwh::float                          as balance_mwh,
        source_percentage::float                  as balance_percentage,
        loaded_at::timestamp_ntz                  as loaded_at
    from src_balance 

)

select
    balance_id,
    date_id,
    region_id,
    technology_id,
    time_trunc,
    balance_mwh,
    balance_percentage,
    loaded_at
from renamed_casted