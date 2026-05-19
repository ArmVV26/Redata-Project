/*
    =======================================================================
    generate_database_name
    -----------------------------------------------------------------------
    Macro personalizada para resolver el nombre de la base de datos.

    Parámetros:
        custom_database_name: base de datos definida en la configuración del modelo.
        node: nodo de dbt que se está compilando. Parámetro requerido por dbt.

    Uso:
        Si el modelo no define una base de datos específica, usa target.database.
        Si la define, utiliza ese valor aplicando trim.

    Nota:
        Esta macro permite controlar la separación entre entornos, por ejemplo
        DEV, CI o PRO, sin repetir lógica en cada modelo.
    =======================================================================
*/

{% macro generate_database_name(custom_database_name=none, node=none) -%}

    {%- if custom_database_name is none -%}
        {{ target.database }}
    {%- else -%}
        {{ custom_database_name | trim }}
    {%- endif -%}

{%- endmacro %}