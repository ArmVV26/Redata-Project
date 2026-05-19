import snowflake.connector
import uuid
import json
import os
import logging
from dotenv import load_dotenv
from config import BRONZE_DATABASE, BRONZE_SCHEMA

load_dotenv()
logger = logging.getLogger(__name__)


def get_connection():
    return snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA"),
        role=os.getenv("SNOWFLAKE_ROLE"),
    )


def already_loaded(
    cursor,
    table: str,
    start_date: str,
    end_date: str,
    geo_id: str = None,
    time_trunc: str = "month",
) -> bool:
    """
    Comprueba si este rango ya fue cargado CORRECTAMENTE en Bronze.

    Criterio de 'carga correcta':
      - ERROR_MESSAGE IS NULL
      - HTTP_STATUS_CODE BETWEEN 200 AND 299
      - RAW_JSON IS NOT NULL

    Si la carga previa fue un error, devuelve False → se reintenta.
    Esto evita que un error guardado bloquee futuras cargas correctas.
    """
    base_conditions = """
        START_DATE        = %s
        AND END_DATE      = %s
        AND TIME_TRUNC    = %s
        AND ERROR_MESSAGE IS NULL
        AND HTTP_STATUS_CODE BETWEEN 200 AND 299
        AND RAW_JSON IS NOT NULL
    """

    if geo_id:
        cursor.execute(
            f"""
            SELECT COUNT(*)
            FROM {BRONZE_DATABASE}.{BRONZE_SCHEMA}.{table}
            WHERE {base_conditions}
                AND GEO_ID = %s
            """,
            (start_date, end_date, time_trunc, geo_id),
        )
    else:
        cursor.execute(
            f"""
            SELECT COUNT(*)
            FROM {BRONZE_DATABASE}.{BRONZE_SCHEMA}.{table}
            WHERE {base_conditions}
            """,
            (start_date, end_date, time_trunc),
        )

    return cursor.fetchone()[0] > 0


def insert_record(
    cursor,
    table: str,
    endpoint_name: str,
    source_url: str,
    start_date: str,
    end_date: str,
    raw_json: dict | None,
    http_status_code: int | None,
    error_message: str | None,
    geo_id: str = None,
    time_trunc: str = "month",
):
    """
    Inserta un registro en la tabla Bronze, incluyendo HTTP_STATUS_CODE y ERROR_MESSAGE.
    Funciona tanto para cargas correctas como para registros de error.
    """
    request_id   = str(uuid.uuid4())
    raw_json_str = json.dumps(raw_json, ensure_ascii=False) if raw_json is not None else None

    # Columnas y valores comunes
    common_cols = (
        "REQUEST_ID, LOADED_AT, SOURCE_URL, ENDPOINT_NAME, "
        "TIME_TRUNC, START_DATE, END_DATE, "
        "HTTP_STATUS_CODE, ERROR_MESSAGE, RAW_JSON"
    )
    common_vals = (
        request_id,
        source_url,
        endpoint_name,
        time_trunc,
        start_date,
        end_date,
        http_status_code,
        error_message,
    )

    if geo_id is not None:
        cursor.execute(
            f"""
            INSERT INTO {BRONZE_DATABASE}.{BRONZE_SCHEMA}.{table}
                ({common_cols}, GEO_ID)
            SELECT
                %s,
                CURRENT_TIMESTAMP(),
                %s, %s, %s, %s, %s,
                %s, %s,
                TO_VARIANT(PARSE_JSON(%s)),
                %s
            """,
            (*common_vals, raw_json_str, geo_id),
        )
    else:
        cursor.execute(
            f"""
            INSERT INTO {BRONZE_DATABASE}.{BRONZE_SCHEMA}.{table}
                ({common_cols})
            SELECT
                %s,
                CURRENT_TIMESTAMP(),
                %s, %s, %s, %s, %s,
                %s, %s,
                TO_VARIANT(PARSE_JSON(%s))
            """,
            (*common_vals, raw_json_str),
        )