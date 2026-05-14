select
    component_id,
    time_trunc,
    datetime_ree,
    count(*) as records
from {{ ref('market_measurements') }}
group by
    component_id,
    time_trunc,
    datetime_ree
having count(*) > 1