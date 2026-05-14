select
    technology_id,
    region_id,
    time_trunc,
    datetime_ree,
    count(*) as records
from {{ ref('balance_measurements') }}
group by
    technology_id,
    region_id,
    time_trunc,
    datetime_ree
having count(*) > 1