/*
    =======================================================================
    generate_schema_name
    -----------------------------------------------------------------------
    Macro personalizada para resolver el nombre del schema.

    Parámetros:
        custom_schema_name: schema definido en la configuración del modelo.
        node: nodo de dbt que se está compilando. Parámetro requerido por dbt.

    Uso:
        Si el modelo no define un schema específico, usa target.schema.
        Si lo define, utiliza ese valor aplicando trim.

    Nota:
        Esta macro evita que dbt concatene automáticamente el schema del target
        con el custom schema. Así se mantiene una estructura de schemas más
        limpia y controlada por capa.
    =======================================================================
*/

{% macro generate_schema_name(custom_schema_name=none, node=none) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}