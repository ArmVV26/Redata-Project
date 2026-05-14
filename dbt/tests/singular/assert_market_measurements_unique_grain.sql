/*
    Test de unicidad para la tabla core de mercado eléctrico.
    Comprueba que no existan duplicados para la granularidad esperada:
    component_id + time_trunc + datetime_ree.
*/

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