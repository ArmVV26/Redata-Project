<div align="center">

  <h1>⚡ REData Analytics Pipeline</h1>
  <h3 style="font-style: italic; margin-top: -0.25rem">Ingesta, modelado y análisis del sistema eléctrico español</h3>

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)

</div>

---

> [!NOTE]
> ## 🔌 Descripción del Proyecto
> ### Español
> **REData Analytics Pipeline** es un proyecto de ingeniería de datos orientado a la ingesta, transformación, modelado y visualización de información pública del sistema eléctrico español a partir de la API de **Red Eléctrica de España (REData)**.
>
> El proyecto implementa una arquitectura analítica por capas (**Bronze, Silver y Gold**) sobre **Snowflake**, usando **Python** para la ingesta, **dbt** para el modelado de datos y **Power BI** para la explotación visual de los casos de uso.
>
> ### English
> **REData Analytics Pipeline** is a data engineering project focused on ingesting, transforming, modelling and visualising public information from the Spanish electricity system using the **Red Eléctrica de España (REData)** API.
>
> The project implements a layered analytical architecture (**Bronze, Silver and Gold**) on **Snowflake**, using **Python** for ingestion, **dbt** for data modelling and **Power BI** for dashboarding and business analysis.

---

## 📚 Índice

- [📚 Índice](#-índice)
- [🎯 Objetivo del Proyecto](#-objetivo-del-proyecto)
- [📁 Estructura del Proyecto](#-estructura-del-proyecto)
- [🏗️ Arquitectura de Datos](#️-arquitectura-de-datos)
  - [Bronze](#bronze)
  - [Silver](#silver)
  - [Gold](#gold)
- [🔄 Flujo de Datos](#-flujo-de-datos)
- [🤖 Automatización con GitHub Actions](#-automatización-con-github-actions)
- [📊 Casos de Uso Analíticos](#-casos-de-uso-analíticos)
- [🧪 Calidad de Datos](#-calidad-de-datos)
- [🚀 Instalación y Configuración](#-instalación-y-configuración)
  - [Requisitos Previos](#requisitos-previos)
  - [Clonar el Repositorio](#clonar-el-repositorio)
  - [Variables de Entorno](#variables-de-entorno)
- [⚙️ Ejecución del Proyecto](#️-ejecución-del-proyecto)
  - [Ingesta de Datos](#ingesta-de-datos)
  - [Ejecución de dbt](#ejecución-de-dbt)
  - [Snapshots](#snapshots)
- [📈 Visualización en Power BI](#-visualización-en-power-bi)
- [🧠 Decisiones de Modelado](#-decisiones-de-modelado)
- [👨‍💻 Créditos](#-créditos)
- [📄 Licencia](#-licencia)

---

## 🎯 Objetivo del Proyecto

El objetivo principal de este proyecto es construir un pipeline de datos completo que permita analizar la evolución del sistema eléctrico español a partir de datos públicos de REData.

El proyecto cubre el ciclo completo de un proceso de ingeniería de datos:

- Extracción de datos desde una API pública.
- Carga de respuestas RAW en Snowflake.
- Transformación y normalización de datos con dbt.
- Construcción de modelos analíticos por capas.
- Aplicación de tests de calidad y validación de granularidad.
- Uso de modelos incrementales para optimizar cargas.
- Uso de snapshots para demostrar trazabilidad histórica de catálogos.
- Creación de marts orientados a casos de uso concretos.
- Visualización final mediante Power BI.

---

## 📁 Estructura del Proyecto

```text
Redata-Project/
├── .github/
│   └── workflows/
│       └── redata_ingestion.yml
├── dbt/
│   ├── analyses/
│   │   └── .gitkeep
│   ├── macros/
│   │   ├── .gitkeep
│   │   ├── clean_text.sql
│   │   ├── deduplicate_by_lastest.sql
│   │   ├── generate_database_name.sql
│   │   ├── generate_schema_name.sql
│   │   └── to_percentage.sql
│   ├── models/
│   │   ├── bronze/
│   │   │   └── _red_electrica__sources.yml
│   │   ├── gold/
│   │   │   ├── core/
│   │   │   │   ├── dimension/
│   │   │   │   │   ├── _dim__models.yml
│   │   │   │   │   ├── dim_date.sql
│   │   │   │   │   ├── dim_price_component.sql
│   │   │   │   │   ├── dim_region.sql
│   │   │   │   │   └── dim_technology.sql
│   │   │   │   └── facts/
│   │   │   │       ├── _fct__models.yml
│   │   │   │       ├── fct_balance.sql
│   │   │   │       ├── fct_generation.sql
│   │   │   │       └── fct_market.sql
│   │   │   └── marts/
│   │   │       ├── _marts__models.yml
│   │   │       ├── monthly_balance_region.sql
│   │   │       ├── monthly_generation_mix.sql
│   │   │       └── monthly_renewable_vs_price.sql
│   │   └── silver/
│   │       ├── core/
│   │       │   ├── _core__models.yml
│   │       │   ├── balance_measurements.sql
│   │       │   ├── generation_measurements.sql
│   │       │   └── market_measurements.sql
│   │       ├── reference/
│   │       │   ├── _reference__models.yml
│   │       │   ├── ref_energy_category.sql
│   │       │   ├── ref_price_component.sql
│   │       │   ├── ref_regions.sql
│   │       │   └── ref_technology.sql
│   │       └── staging/
│   │           ├── _staging__models.yml
│   │           ├── stg_red_electrica__balance_measurement.sql
│   │           ├── stg_red_electrica__generation_measurement.sql
│   │           └── stg_red_electrica__market_measurement.sql
│   ├── seeds/
│   │   ├── _seeds.yml
│   │   ├── .gitkeep
│   │   └── regions.csv
│   ├── snapshots/
│   │   ├── _snapshots.yml
│   │   ├── .gitkeep
│   │   ├── ref_price_component_check_snp.sql
│   │   └── ref_technology_check_snp.sql
│   ├── tests/
│   │   ├── singular/
│   │   │   ├── assert_balance_measurements_unique_grain.sql
│   │   │   ├── assert_core_dates_not_in_future.sql
│   │   │   ├── assert_core_referential_integrity.sql
│   │   │   ├── assert_generation_measurements_unique_grain.sql
│   │   │   └── assert_market_measurements_unique_grain.sql
│   │   └── .gitkeep
│   ├── .gitignore
│   ├── dbt_project.yml
│   ├── package-lock.yml
│   ├── packages.yml
│   └── README.md
├── ingestion/
│   ├── src/
│   │   ├── api_client.py
│   │   ├── config.py
│   │   ├── main.py
│   │   └── snowflake_loader.py
│   ├── .gitignore
│   └── requirements.txt
├── LICENSE
└── README.md
```

---

## 🏗️ Arquitectura de Datos

El proyecto sigue una arquitectura medallion dividida en tres capas principales:

```text
REData API
   │
   ▼
Python Ingestion
   │
   ▼
Snowflake Bronze
   │
   ▼
dbt Silver
   ├── Staging
   ├── Reference
   └── Core
   │
   ▼
dbt Gold
   ├── Dimensions
   ├── Facts
   └── Marts
   │
   ▼
Power BI
```

> [!NOTE]
> El diagrama DBML del modelo de datos no se incluye como imagen en este README. La estructura de capas se documenta en texto para evitar depender de capturas externas, y el detalle completo de tablas, campos y relaciones se mantiene en el archivo DBML/documentación técnica del proyecto.

### Bronze

La capa **Bronze** almacena las respuestas originales de la API en formato RAW, conservando la respuesta JSON completa y los metadatos principales de la petición.

Fuentes principales:

- `balance_response`: respuestas del endpoint de balance eléctrico.
- `generation_response`: respuestas del endpoint de estructura de generación.
- `market_response`: respuestas del endpoint de componentes del precio de la energía.

Esta capa prioriza la trazabilidad y la capacidad de reprocesar los datos desde el origen sin depender de transformaciones previas.

---

### Silver

La capa **Silver** transforma los datos RAW en modelos limpios, normalizados y preparados para análisis.

Se divide en tres subcapas:

#### Staging

Modelos encargados de aplanar el JSON original, tipar campos, normalizar textos básicos y conservar trazabilidad de ingesta.

- `stg_red_electrica__balance_measurement`
- `stg_red_electrica__generation_measurement`
- `stg_red_electrica__market_measurement`

#### Reference

Modelos de referencia usados para construir catálogos analíticos reutilizables:

- `ref_regions`
- `ref_technology`
- `ref_energy_category`
- `ref_price_component`

#### Core

Modelos incrementales que consolidan las mediciones finales de Silver, deduplican registros y generan claves surrogate estables.

- `balance_measurements`
- `generation_measurements`
- `market_measurements`

---

### Gold

La capa **Gold** contiene los modelos finales de consumo analítico.

Se divide en:

#### Dimensions

- `dim_date`: calendario reutilizable para análisis temporal.
- `dim_region`: catálogo de regiones.
- `dim_technology`: catálogo vigente de tecnologías eléctricas.
- `dim_price_component`: catálogo vigente de componentes del precio.

#### Facts

- `fct_balance`: mediciones de balance eléctrico por fecha, región y tecnología.
- `fct_generation`: mediciones de generación eléctrica por fecha y tecnología.
- `fct_market`: mediciones de mercado por fecha y componente de precio.

#### Marts

Modelos orientados directamente a los casos de uso definidos para Power BI:

- `monthly_balance_region`
- `monthly_generation_mix`
- `monthly_renewable_vs_price`

---

## 🔄 Flujo de Datos

El flujo general del proyecto es el siguiente:

1. **Ingesta con Python**
   - Se realizan peticiones a la API de REData.
   - Se parametrizan endpoints, rango temporal, granularidad y región cuando aplica.
   - Se carga la respuesta completa en Snowflake como JSON RAW.

2. **Declaración de fuentes en dbt**
   - Se definen las tablas RAW como sources.
   - Se añaden tests de calidad básicos como `not_null`, `unique` y `accepted_values`.
   - Se configura freshness para controlar la actualización de las fuentes.

3. **Transformación en Silver**
   - Se aplana el JSON con `lateral flatten`.
   - Se normalizan nombres y tipos de datos.
   - Se construyen referencias comunes para tecnologías, regiones, categorías energéticas y componentes de precio.
   - Se generan modelos incrementales con deduplicación por última carga.

4. **Modelado en Gold**
   - Se crean dimensiones y facts listas para consumo analítico.
   - Se construyen marts mensuales enfocados a los casos de uso principales.

5. **Visualización en Power BI**
   - Se conectan los modelos Gold con Power BI.
   - Se crean dashboards para analizar generación, balance eléctrico, renovables y precio de mercado.

---

## 🤖 Automatización con GitHub Actions

El repositorio incluye un workflow en `.github/workflows/redata_ingestion.yml` para automatizar la ingesta hacia Snowflake Bronze.

El workflow contempla dos formas de ejecución:

- **Ejecución programada:** el día 15 de cada mes a las 06:00 UTC, usando el modo `monthly`.
- **Ejecución manual:** desde la interfaz de GitHub Actions, pudiendo elegir entre `monthly`, `backfill` o `custom`.

En ejecución manual, el modo `custom` permite indicar `start_date` y `end_date`, lo que resulta útil para pruebas controladas de carga e incrementalidad.

La automatización realiza los siguientes pasos:

1. Descarga el código del repositorio.
2. Configura Python 3.11.
3. Instala las dependencias de `ingestion/requirements.txt`.
4. Determina el modo de ejecución y las fechas.
5. Ejecuta `python src/main.py` con los parámetros correspondientes.

Las credenciales de Snowflake se gestionan mediante **GitHub Secrets**, evitando exponer usuarios, contraseñas o roles en el repositorio.

> [!NOTE]
> El workflow también deja planteada una integración con dbt Cloud para lanzar automáticamente el job de transformación después de la ingesta. En este proyecto queda documentada pero desactivada porque el plan gratuito de dbt Cloud no permite usar la API REST de jobs. Como alternativa, se podría ejecutar `dbt build` directamente desde GitHub Actions usando dbt Core.

---

## 📊 Casos de Uso Analíticos

### 1. Mix mensual de generación eléctrica

Permite analizar la evolución mensual de la generación eléctrica por tecnología.

Modelo principal:

```text
monthly_generation_mix
```

Preguntas que responde:

- ¿Qué tecnologías tienen mayor peso en el mix eléctrico?
- ¿Cómo evoluciona la generación renovable y no renovable?
- ¿Qué tecnologías dominan cada periodo mensual?

---

### 2. Balance eléctrico mensual por región

Permite comparar el balance eléctrico entre regiones y tecnologías.

Modelo principal:

```text
monthly_balance_region
```

Preguntas que responde:

- ¿Qué regiones tienen mayor volumen de balance eléctrico?
- ¿Qué tecnologías pesan más dentro de cada región?
- ¿Cómo cambia el reparto tecnológico por ámbito geográfico?

---

### 3. Relación entre renovables y precio de mercado

Permite estudiar la relación entre el peso mensual de la generación renovable y el precio del mercado diario.

Modelo principal:

```text
monthly_renewable_vs_price
```

Preguntas que responde:

- ¿Cómo evoluciona el porcentaje de generación renovable?
- ¿Cómo evoluciona el precio mensual del mercado diario?
- ¿Existe relación visual entre mayor peso renovable y variaciones en el precio?

---

## 🧪 Calidad de Datos

El proyecto incorpora diferentes controles de calidad en dbt:

### Tests genéricos

- `not_null`
- `unique`
- `accepted_values`
- Validación de relaciones entre modelos.

### Tests singulares

- `assert_balance_measurements_unique_grain.sql`
- `assert_generation_measurements_unique_grain.sql`
- `assert_market_measurements_unique_grain.sql`
- `assert_core_dates_not_in_future.sql`
- `assert_core_referential_integrity.sql`

Estos tests permiten validar aspectos clave como:

- La unicidad de la granularidad de las tablas core.
- La ausencia de fechas futuras no esperadas.
- La integridad referencial entre hechos y dimensiones.
- La consistencia de los modelos finales antes de consumirlos desde Power BI.

---

## 🚀 Instalación y Configuración

### Requisitos Previos

- **Python 3.10+**
- **Snowflake**
- **dbt Core** o **dbt Cloud**
- **Power BI Desktop**
- **Git**
- Cuenta o acceso a la API pública de **REData**

---

### Clonar el Repositorio

```bash
git clone https://github.com/ArmVV26/Redata-Project.git
cd Redata-Project
```

---

### Variables de Entorno

El proyecto necesita variables de entorno para conectarse a Snowflake y controlar el entorno de ejecución.

Ejemplo orientativo:

```bash
DBT_ENVIRONMENTS=DEV
SNOWFLAKE_ACCOUNT=<account>
SNOWFLAKE_USER=<user>
SNOWFLAKE_PASSWORD=<password>
SNOWFLAKE_ROLE=<role>
SNOWFLAKE_WAREHOUSE=<warehouse>
SNOWFLAKE_DATABASE=<database>
SNOWFLAKE_SCHEMA=<schema>
```

> [!WARNING]
> No subas credenciales reales al repositorio. Usa archivos `.env`, secretos de GitHub Actions o variables de entorno configuradas en dbt Cloud/Snowflake.

---

## ⚙️ Ejecución del Proyecto

### Ingesta de Datos

La ingesta se implementa en Python dentro del directorio `ingestion/`. Su responsabilidad es consultar la API pública de REData, recuperar las respuestas de los endpoints configurados y cargarlas en la capa **Bronze** de Snowflake manteniendo el JSON original y los metadatos de trazabilidad.

El proceso está dividido en cuatro piezas principales:

| Archivo | Responsabilidad |
|---|---|
| `config.py` | Define los endpoints, rangos de fechas, granularidad temporal, regiones geográficas y configuración de conexión lógica hacia Bronze. |
| `api_client.py` | Realiza las llamadas HTTP a REData, aplica reintentos ante errores temporales y devuelve tanto la respuesta JSON como información de error si la petición falla. |
| `snowflake_loader.py` | Gestiona la conexión con Snowflake, comprueba si una carga correcta ya existe y realiza la inserción en las tablas RAW de Bronze. |
| `main.py` | Orquesta la ejecución completa, permite elegir el modo de ingesta y coordina endpoints, fechas, regiones, llamadas API e inserciones. |

Endpoints principales usados:

```text
balance/balance-electrico
generacion/estructura-generacion
mercados/componentes-precio-energia-cierre-desglose
```

La ingesta soporta tres modos de ejecución:

```bash
# Backfill histórico con los rangos definidos en config.py
python src/main.py --mode backfill

# Carga mensual automática del mes anterior
python src/main.py --mode monthly

# Carga manual de un rango concreto
python src/main.py   --mode custom   --start-date 2026-01-01T00:00   --end-date 2026-04-30T23:59
```

El modo `monthly` calcula automáticamente el rango completo del mes anterior al día de ejecución. El modo `custom` permite preparar pruebas controladas, por ejemplo cargar varios meses concretos para validar incrementalidad en dbt.

#### Trazabilidad e idempotencia de la ingesta

Cada registro insertado en Bronze incluye campos de control como `request_id`, `loaded_at`, `source_url`, `endpoint_name`, `time_trunc`, `start_date`, `end_date`, `http_status_code`, `error_message` y `raw_json`.

Antes de insertar una nueva respuesta, la ingesta comprueba si ese endpoint, rango temporal, región y granularidad ya existen como una carga correcta en Snowflake. Si ya existe una carga válida, el proceso la omite para evitar duplicados. Si la carga previa fue un error, se permite reintentar en futuras ejecuciones.

Además, los errores de API no detienen necesariamente todo el proceso: se guardan en Bronze con `raw_json = null`, `http_status_code` y `error_message`, de forma que la incidencia queda trazada y puede revisarse posteriormente.

---

### Ejecución de dbt

Desde el directorio `dbt/`:

```bash
cd dbt
```

Instalar dependencias:

```bash
dbt deps
```

Cargar seeds:

```bash
dbt seed
```

Ejecutar modelos:

```bash
dbt build
```

Ejecutar únicamente una capa concreta:

```bash
# Silver
dbt build --select models/silver

# Gold
dbt build --select models/gold

# Marts
dbt build --select models/gold/marts
```

Ejecutar tests:

```bash
dbt test
```

Generar documentación:

```bash
dbt docs generate
dbt docs serve
```

---

### Snapshots

El proyecto incluye snapshots para mantener trazabilidad histórica sobre catálogos que podrían cambiar con el tiempo:

- `ref_price_component_check_snp.sql`
- `ref_technology_check_snp.sql`

Ejecución:

```bash
dbt snapshot
```

Después de ejecutar snapshots, se puede lanzar el build de Gold:

```bash
dbt build --select models/gold
```

> [!NOTE]
> En este proyecto los snapshots también cumplen una función educativa: demostrar cómo se podría controlar la evolución histórica de catálogos analíticos aunque los cambios reales en REData no sean frecuentes.

---

## 📈 Visualización en Power BI

La capa Gold está diseñada para conectarse desde Power BI y construir dashboards sobre modelos limpios y estables.

Modelos recomendados para visualización:

- `monthly_generation_mix`
- `monthly_balance_region`
- `monthly_renewable_vs_price`
- `dim_date`
- `dim_region`
- `dim_technology`
- `dim_price_component`

Recomendación de modelado en Power BI:

- Usar los marts como tablas principales para los casos de uso.
- Relacionar las dimensiones mediante sus claves correspondientes.
- Usar `dim_date` para filtros temporales.
- Ordenar campos como `year_month_label` usando `year_month` para evitar problemas de ordenación alfabética.

---

## 🧠 Decisiones de Modelado

### Arquitectura Bronze, Silver y Gold

Se ha elegido una arquitectura por capas para separar claramente las responsabilidades del pipeline:

- **Bronze** conserva el dato original.
- **Silver** limpia, normaliza y deduplica.
- **Gold** expone modelos analíticos listos para negocio.

Esta separación permite trazabilidad, mantenibilidad y facilidad para reprocesar datos si cambia la lógica de transformación.

---

### Uso de modelos incrementales

Los modelos core de Silver se materializan como incrementales para evitar reprocesar todo el histórico en cada ejecución.

La estrategia usada es:

```text
incremental_strategy = merge
unique_key = *_id
```

Además, se conserva la última versión disponible de cada medición usando `loaded_at` y `request_id` como criterios de ordenación.

---

### Uso de claves surrogate

Se generan claves surrogate para mantener identificadores analíticos estables, especialmente en entidades donde el identificador de origen puede variar entre endpoints o no ser suficiente por sí solo.

Ejemplos:

- `technology_id`
- `component_id`
- `balance_id`
- `generation_id`
- `market_id`

---

### Exclusión de tecnologías compuestas

En los marts mensuales se excluyen tecnologías marcadas como `is_composite = true` para evitar doble conteo en los agregados.

Esto es especialmente importante en análisis de generación y balance eléctrico, donde algunas categorías pueden actuar como agrupaciones de otras tecnologías.

---

### Marts mensuales orientados a casos de uso

Aunque las capas Silver y Gold Core están preparadas para trabajar con distintas granularidades temporales (`hour`, `day`, `month`, `year`), los marts se han diseñado específicamente a nivel mensual porque los casos de uso principales del proyecto se analizan a esa granularidad.

Esta decisión evita crear tablones innecesarios y mantiene la capa Gold más clara, reutilizable y enfocada.

---

## 👨‍💻 Créditos

Proyecto desarrollado por:

**Armando Vaquero Vargas**

Proyecto realizado con fines formativos como parte de un portfolio/proyecto académico de ingeniería de datos, aplicando buenas prácticas de ingesta, modelado analítico, calidad de datos y visualización.

---

## 📄 Licencia

© 2026 - Armando Vaquero Vargas. Todos los derechos reservados.

Este proyecto ha sido desarrollado exclusivamente con fines académicos y de aprendizaje.