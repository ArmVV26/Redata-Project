import snowflake.connector
import uuid
import json
import os
import logging
from dotenv import load_dotenv

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


"""Comprueba si este rango ya fue ingestado previamente"""
def already_loaded(
        cursor, table: str, start_date: str, end_date: str,
        geo_id: str = None, time_trunc: str = "month"
    ) -> bool:
    
    if geo_id:
        cursor.execute(f"""
            SELECT COUNT(*) 
            FROM PRO_REDATA_BRONZE.RAW.{table}
            WHERE START_DATE = %s 
                AND END_DATE = %s
                AND GEO_ID = %s
                AND TIME_TRUNC = %s
        """, (start_date, end_date, geo_id, time_trunc))
    else:
        cursor.execute(f"""
            SELECT COUNT(*) 
            FROM PRO_REDATA_BRONZE.RAW.{table}
            WHERE START_DATE = %s 
                AND END_DATE = %s
                AND TIME_TRUNC = %s
        """, (start_date, end_date, time_trunc))
    return cursor.fetchone()[0] > 0


"""Inserta un registro en la tabla Bronze correspondiente"""
def insert_record(
        cursor, table: str, endpoint_name: str, source_url: str,
        start_date: str, end_date: str, raw_json: dict,
        geo_id: str = None, time_trunc: str = "month"
    ):

    request_id = str(uuid.uuid4());
    raw_json_str = json.dumps(raw_json, ensure_ascii=False)

    if geo_id is not None:
        cursor.execute(f"""
            INSERT INTO PRO_REDATA_BRONZE.RAW.{table}
                (REQUEST_ID, LOADED_AT, SOURCE_URL, ENDPOINT_NAME, TIME_TRUNC, START_DATE, END_DATE, GEO_ID, RAW_JSON)
            SELECT
                %s,
                CURRENT_TIMESTAMP(),
                %s, %s, %s, %s, %s, %s,
                TO_VARIANT(PARSE_JSON(%s))
        """, (
            request_id,
            source_url,
            endpoint_name,
            time_trunc,
            start_date,
            end_date,
            geo_id,
            raw_json_str
        ))

    else:
        cursor.execute(f"""
            INSERT INTO PRO_REDATA_BRONZE.RAW.{table}
                (REQUEST_ID, LOADED_AT, SOURCE_URL, ENDPOINT_NAME, TIME_TRUNC, START_DATE, END_DATE, RAW_JSON)
            SELECT
                %s,
                CURRENT_TIMESTAMP(),
                %s, %s, %s, %s, %s,
                TO_VARIANT(PARSE_JSON(%s))
        """, (
            request_id,
            source_url,
            endpoint_name,
            time_trunc,
            start_date,
            end_date,
            raw_json_str
        ))