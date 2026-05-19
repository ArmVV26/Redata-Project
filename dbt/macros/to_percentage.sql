/*
    =======================================================================
    to_percentage
    -----------------------------------------------------------------------
    Macro para convertir valores en formato ratio a porcentaje.

    Parámetros:
        column_name: columna o expresión SQL en formato ratio.
        decimals: número de decimales del resultado. Por defecto, 2.

    Uso:
        Convierte valores como 0.2534 en 25.34, facilitando su consumo en
        facts, marts y visualizaciones.

    Ejemplo:
        {{ to_percentage('source_percentage') }}
    =======================================================================
*/

{% macro to_percentage(column_name, decimals=2) -%}
    round({{ column_name }} * 100, {{ decimals }})
{%- endmacro %}