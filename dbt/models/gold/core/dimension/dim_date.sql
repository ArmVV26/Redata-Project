/*
    =======================================================================
    dim_date
    -----------------------------------------------------------------------
    Dimension de fechas.

    Capa: Gold / Core
    Origen: dbt_utils.date_spine
    Materialización: table
    Granularidad: date_id
    Clave: date_id.

    Genera un calendario diario reutilizable para relacionar las facts con
    atributos temporales como año, trimestre, mes o dia de la semana.
    =======================================================================
*/

with

dates as (

     -- Calendario base del modelo analítico. Amplio para cubrir histórico y futuras cargas
    {{
        dbt_utils.date_spine(
            datepart="day",
            start_date="cast('2013-01-01' as date)",
            end_date="cast('2030-12-31' as date)"
        )
    }}

),

renamed_casted as (

    select
        date_day::date                              as date_id,
        year(date_day)                              as year,
        quarter(date_day)                           as quarter,
        date_trunc('month', date_day)::date         as month_start_date,
        month(date_day)                             as month_number,
        monthname(date_day)                         as month_name,
        year(date_day) * 100 + month(date_day)      as year_month,
        to_char(date_day, 'YYYY-MM')                as year_month_label,
        day(date_day)                               as day_of_month,
        dayofweek(date_day)                         as day_of_week,
        dayname(date_day)                           as day_name
    from dates

)

select
    date_id,
    year,
    quarter,
    month_start_date,
    month_number,
    month_name,
    year_month,
    year_month_label,
    day_of_month,
    day_of_week,
    day_name
from renamed_casted