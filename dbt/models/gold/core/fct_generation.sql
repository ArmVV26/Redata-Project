with

src_generation as (

    select
        generation_id,
        technology_id,
        time_trunc,
        period_start_date,
        value_mwh,
        source_percentage,
        loaded_at
    from {{ ref('generation_measurements') }}

),

renamed_casted as (

    select
        generation_id::varchar                    as generation_id,
        period_start_date::date                   as date_id,
        technology_id::varchar                    as technology_id,
        time_trunc::varchar                       as time_trunc,
        value_mwh::float                          as generation_mwh,
        source_percentage::float                  as generation_percentage,
        loaded_at::timestamp_ntz                  as loaded_at
    from src_generation 

)

select
    generation_id,
    date_id,
    technology_id,
    time_trunc,
    generation_mwh,
    generation_percentage,
    loaded_at
from renamed_casted