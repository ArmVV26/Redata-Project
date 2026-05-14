/*
    Test de unicidad para la tabla core de generación eléctrica.
    Comprueba que no existan duplicados para la granularidad esperada:
    technology_id + time_trunc + datetime_ree.
*/

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