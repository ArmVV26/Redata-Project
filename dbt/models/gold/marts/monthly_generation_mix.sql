with

dim_technology as (

    select
        technology_id,
        is_composite
    from {{ ref('dim_technology') }}

),

fct_generation as (

    select
        g.month_start_date,
        g.technology_id,
        g.generation_mwh,
        g.loaded_at
    from {{ ref('fct_generation') }} g
    inner join dim_technology t
        on g.technology_id = t.technology_id
    where g.time_trunc = 'month'
        and t.is_composite = false

),

monthly_generation as (

    select
        month_start_date,
        technology_id,
        sum(generation_mwh)     as generation_mwh,
        max(loaded_at)          as loaded_at
        from fct_generation
        group by
            month_start_date,
            technology_id
),

monthly_total_generation as (

    select
        month_start_date,
        sum(generation_mwh)     as total_generation_mwh
    from monthly_generation
    group by 
        month_start_date

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'g.month_start_date',
            'g.technology_id'
        ]) }}                                                                   as monthly_generation_mix_id,
        g.month_start_date,
        g.technology_id,
        g.generation_mwh,
        t.total_generation_mwh,
        div0(g.generation_mwh, t.total_generation_mwh)                          as generation_share,
        {{ to_percentage('div0(g.generation_mwh, t.total_generation_mwh)') }}   as generation_share_pct,
        g.loaded_at
    from monthly_generation g
    inner join monthly_total_generation t
        on g.month_start_date = t.month_start_date

)

select
    monthly_generation_mix_id,
    month_start_date,
    technology_id,
    generation_mwh,
    total_generation_mwh,
    generation_share,
    generation_share_pct,
    loaded_at
from final