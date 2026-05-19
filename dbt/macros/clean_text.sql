/*
    =======================================================================
    clean_text
    -----------------------------------------------------------------------
    Macro para limpiar campos de texto.

    Parámetros:
        column_name: columna o expresión SQL de tipo texto.

    Uso:
        Elimina espacios al inicio y al final, y convierte cadenas vacías en
        null. Se utiliza principalmente en staging y referencias antes de hacer
        joins, generar claves o construir catálogos analíticos.

    Ejemplo:
        {{ clean_text('technology_name') }}
    =======================================================================
*/

{% macro clean_text(column_name) -%}
    nullif(trim({{ column_name }}), '')
{%- endmacro %}