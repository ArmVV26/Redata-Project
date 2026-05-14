/*
    Test de unicidad para la tabla core de balance eléctrico.
    Comprueba que no existan duplicados para la granularidad esperada:
    technology_id + region_id + time_trunc + datetime_ree.
*/

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