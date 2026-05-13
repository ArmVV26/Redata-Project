with

src_market as (

    select
        market_id,
        component_id,
        time_trunc,
        period_start_date,
        value_eur_mwh,
        source_percentage,
        loaded_at
    from {{ ref('market_measurements') }}

),

renamed_casted as (

    select
        market_id::varchar                        as market_id,
        period_start_date::date                   as date_id,
        component_id::varchar                     as component_id,
        time_trunc::varchar                       as time_trunc,
        value_eur_mwh::float                      as market_eur_mwh,
        source_percentage::float                  as market_percentage,
        loaded_at::timestamp_ntz                  as loaded_at
    from src_market 

)

select
    market_id,
    date_id,
    component_id,
    time_trunc,
    market_eur_mwh,
    market_percentage,
    loaded_at
from renamed_casted