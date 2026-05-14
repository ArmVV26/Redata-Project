/*
    Macro para limpiar y normalizar campos de texto.
    Aplica transformaciones básicas para estandarizar valores
    antes de usarlos en modelos, joins o claves.
*/

{% macro clean_text(column_name) -%}
    nullif(trim({{ column_name }}), '')
{%- endmacro %}