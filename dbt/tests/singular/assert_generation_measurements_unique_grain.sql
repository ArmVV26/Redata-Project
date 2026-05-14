select
    technology_id,
    time_trunc,
    datetime_ree,
    count(*) as records
from {{ ref('generation_measurements') }}
group by
    technology_id,
    time_trunc,
    datetime_ree
having count(*) > 1