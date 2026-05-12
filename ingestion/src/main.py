import logging, json
from config import ENDPOINTS, DATE_RANGES, BASE_URL, GEO_CANDIDATES
from api_client import fetch_endpoint
from snowflake_loader import get_connection, already_loaded, insert_record

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def run():
    conn = get_connection()
    cursor = conn.cursor()

    total_inserted = 0
    total_skipped  = 0
    total_errors   = 0

    try:
        for endpoint in ENDPOINTS:
            logger.info(f"{'='*50}")
            logger.info(f"Endpoint: {endpoint['name']}")
            logger.info(f"{'='*50}")

            geo_regions = endpoint.get("geo_regions", [])
            iterations = (
                [(geo_id, GEO_CANDIDATES[geo_id]) for geo_id in geo_regions]
                if geo_regions
                else [(None, None)]
            )

            for start_date, end_date in DATE_RANGES:
                for geo_id, geo_limit in iterations:
                    
                    geo_label = f"geo={geo_id}" if geo_id else "sin geo"
                
                    # Saltar si ya existe este rango en Bronze
                    if already_loaded(cursor, endpoint["table"], start_date, end_date, geo_id, endpoint["time_trunc"]):
                        logger.info(f"  [{start_date[:4]}-{end_date[:4]}] [{geo_label}] Ya existe, skipping.\n")
                        total_skipped += 1
                        continue

                    extra_params = {}
                    if geo_id:
                        extra_params = {
                            "geo_limit": geo_limit,
                            "geo_ids": geo_id
                        }

                    # Llamar a la API
                    raw_data = fetch_endpoint(
                        url_path=endpoint["url_path"],
                        start_date=start_date,
                        end_date=end_date,
                        extra_params=extra_params,
                        time_trunc=endpoint["time_trunc"]
                    )

                    if raw_data is None:
                        total_errors += 1
                        continue

                    # Insertar en Bronze
                    source_url = f"{BASE_URL}/{endpoint['url_path']}"
                    insert_record(
                        cursor=cursor,
                        table=endpoint["table"],
                        endpoint_name=endpoint["name"],
                        source_url=source_url,
                        start_date=start_date,
                        end_date=end_date,
                        raw_json=raw_data,
                        geo_id=geo_id,
                        time_trunc=endpoint["time_trunc"]
                    )
                    
                    size = len(json.dumps(raw_data, ensure_ascii=False).encode('utf-8'))

                    conn.commit()
                    logger.info(f"  [{start_date[:4]}-{end_date[:4]}] [{geo_label}] [Size - {size}] Insertado correctamente \n")
                    total_inserted += 1

    finally:
        cursor.close()
        conn.close()

    # Resumen final
    logger.info(f"\n{'='*50}")
    logger.info(f"RESUMEN INGESTION")
    logger.info(f"  Insertados : {total_inserted}")
    logger.info(f"  Skipped    : {total_skipped}")
    logger.info(f"  Errores    : {total_errors}")
    logger.info(f"{'='*50}")


if __name__ == "__main__":
    run()