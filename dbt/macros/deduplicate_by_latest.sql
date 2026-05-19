/*
    =======================================================================
    deduplicate_by_latest
    -----------------------------------------------------------------------
    Macro para generar un ranking de deduplicación.

    Parámetros:
        partition_by: lista de columnas que definen la unicidad lógica.
        order_by: lista de columnas usadas para ordenar cada grupo.
                  Por defecto, ['loaded_at'].

    Uso:
        Devuelve un row_number() particionado por las columnas indicadas y
        ordenado de forma descendente. Se utiliza en modelos incrementales
        para conservar la última versión disponible de cada medición.

    Ejemplo:
        {{ deduplicate_by_latest(
            partition_by=[
                'technology_id',
                'time_trunc',
                'datetime_ree'
            ],
            order_by=[
                'loaded_at',
                'request_id'
            ]
        ) }}
    =======================================================================
*/

{% macro deduplicate_by_latest(partition_by, order_by=['loaded_at']) -%}

    row_number() over (
        partition by
            {%- for column in partition_by %}
                {{ column }}{% if not loop.last %}, {% endif %}
            {%- endfor %}
        order by
            {%- for column in order_by %}
                {{ column }} desc{% if not loop.last %}, {% endif %}
            {%- endfor %}
    )

{%- endmacro %}