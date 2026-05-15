with

src_generation as (

    select
        generation_id,
        technology_id,
        time_trunc,
        datetime_ree,
        datetime_ree::date                          as date_id,
        date_trunc('month', datetime_ree)::date     as month_start_date,
        value_mwh,
        source_percentage,
        loaded_at
    from {{ ref('generation_measurements') }}

),

dim_date as (

    select
        date_id
    from {{ ref('dim_date') }}

),

dim_technology as (

    select
        technology_id
    from {{ ref('dim_technology') }}

),

renamed_casted as (

    select
        g.generation_id::varchar                    as generation_id,
        d.date_id::date                             as date_id,
        g.month_start_date::date                    as month_start_date,
        t.technology_id::varchar                    as technology_id,
        g.time_trunc::varchar                       as time_trunc,
        g.datetime_ree::timestamp_ntz               as datetime_ree,
        g.value_mwh::float                          as generation_mwh,
        g.source_percentage::float                  as generation_percentage,
        g.loaded_at::timestamp_ntz                  as loaded_at
    from src_generation g
    inner join dim_date d
        on g.date_id = d.date_id
    inner join dim_technology t
        on g.technology_id = t.technology_id

)

select
    generation_id,
    date_id,
    month_start_date,
    technology_id,
    time_trunc,
    datetime_ree,
    generation_mwh,
    generation_percentage,
    loaded_at
from renamed_casted