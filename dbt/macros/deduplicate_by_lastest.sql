/*
    Macro para deduplicar registros usando la carga más reciente.
    Genera un ranking por las columnas de partición indicadas
    y ordena por loaded_at descendente por defecto.
*/

{% macro deduplicate_by_latest(partition_by, order_by=['loaded_at']) -%}

    row_number() over(
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