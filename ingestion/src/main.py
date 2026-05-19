import argparse
import logging
import json
from datetime import date, timedelta

from config import ENDPOINTS, DATE_RANGES, BASE_URL, GEO_CANDIDATES
from api_client import fetch_endpoint
from snowflake_loader import get_connection, already_loaded, insert_record

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


# ── Helpers de fechas ────────────────────────────────────────────────────────

def get_previous_month_range() -> tuple[str, str]:
    """Calcula el rango completo del mes anterior al día de ejecución."""
    today      = date.today()
    first_this = today.replace(day=1)
    last_prev  = first_this - timedelta(days=1)
    first_prev = last_prev.replace(day=1)

    start = first_prev.strftime("%Y-%m-%dT00:00")
    end   = last_prev.strftime("%Y-%m-%dT23:59")
    return start, end


def parse_args():
    parser = argparse.ArgumentParser(description="Ingesta REData → Snowflake Bronze")

    parser.add_argument(
        "--mode",
        required=True,
        choices=["backfill", "monthly", "custom"],
        help="Modo de ejecución: backfill | monthly | custom",
    )
    parser.add_argument(
        "--start-date",
        default=None,
        help="Fecha inicio para modo custom (formato: 2026-01-01T00:00)",
    )
    parser.add_argument(
        "--end-date",
        default=None,
        help="Fecha fin para modo custom (formato: 2026-04-30T23:59)",
    )
    return parser.parse_args()


def build_date_ranges(args) -> list[tuple[str, str]]:
    """Devuelve la lista de rangos (start, end) según el modo elegido."""
    if args.mode == "backfill":
        logger.info("Modo: BACKFILL HISTÓRICO")
        return DATE_RANGES

    elif args.mode == "monthly":
        start, end = get_previous_month_range()
        logger.info(f"Modo: MONTHLY — rango: {start} → {end}")
        return [(start, end)]

    elif args.mode == "custom":
        if not args.start_date or not args.end_date:
            raise ValueError(
                "El modo 'custom' requiere --start-date y --end-date.\n"
                "Ejemplo: python main.py --mode custom "
                "--start-date 2026-01-01T00:00 --end-date 2026-04-30T23:59"
            )
        logger.info(f"Modo: CUSTOM — rango: {args.start_date} → {args.end_date}")
        return [(args.start_date, args.end_date)]


# ── Lógica principal ─────────────────────────────────────────────────────────

def run(date_ranges: list[tuple[str, str]]):
    conn   = get_connection()
    cursor = conn.cursor()

    total_inserted = 0
    total_skipped  = 0
    total_errors   = 0

    try:
        for endpoint in ENDPOINTS:
            logger.info("=" * 60)
            logger.info(f"Endpoint: {endpoint['name']}  →  tabla: {endpoint['table']}")
            logger.info("=" * 60)

            geo_regions = endpoint.get("geo_regions", [])
            iterations  = (
                [(geo_id, GEO_CANDIDATES[geo_id]) for geo_id in geo_regions]
                if geo_regions
                else [(None, None)]
            )

            for start_date, end_date in date_ranges:
                for geo_id, geo_limit in iterations:

                    geo_label  = f"geo={geo_id}" if geo_id else "sin geo"
                    range_label = f"[{start_date} → {end_date}] [{geo_label}]"

                    # ── Idempotencia: saltamos si ya existe carga correcta ──
                    if already_loaded(
                        cursor, endpoint["table"],
                        start_date, end_date,
                        geo_id, endpoint["time_trunc"]
                    ):
                        logger.info(f"  {range_label} Ya cargado correctamente, skipping.")
                        total_skipped += 1
                        continue

                    # ── Construir parámetros extra de geo ──────────────────
                    extra_params = {}
                    if geo_id:
                        extra_params = {
                            "geo_limit": geo_limit,
                            "geo_ids":   geo_id,
                        }

                    # ── Llamar a la API ────────────────────────────────────
                    result = fetch_endpoint(
                        url_path=endpoint["url_path"],
                        start_date=start_date,
                        end_date=end_date,
                        extra_params=extra_params,
                        time_trunc=endpoint["time_trunc"],
                    )

                    raw_json         = result["raw_json"]
                    http_status_code = result["http_status_code"]
                    error_message    = result["error_message"]

                    # ── Insertar en Bronze (siempre, correcta o error) ─────
                    source_url = f"{BASE_URL}/{endpoint['url_path']}"
                    insert_record(
                        cursor=cursor,
                        table=endpoint["table"],
                        endpoint_name=endpoint["name"],
                        source_url=source_url,
                        start_date=start_date,
                        end_date=end_date,
                        raw_json=raw_json,
                        http_status_code=http_status_code,
                        error_message=error_message,
                        geo_id=geo_id,
                        time_trunc=endpoint["time_trunc"],
                    )
                    conn.commit()

                    if error_message:
                        logger.warning(
                            f"  {range_label} ERROR guardado en Bronze: "
                            f"HTTP {http_status_code} — {error_message}"
                        )
                        total_errors += 1
                    else:
                        size = len(json.dumps(raw_json, ensure_ascii=False).encode("utf-8"))
                        logger.info(
                            f"  {range_label} Insertado OK — "
                            f"HTTP {http_status_code} — {size} bytes"
                        )
                        total_inserted += 1

    finally:
        cursor.close()
        conn.close()

    logger.info("\n" + "=" * 60)
    logger.info("RESUMEN INGESTA")
    logger.info(f"  Insertados correctamente : {total_inserted}")
    logger.info(f"  Skipped (ya existían)    : {total_skipped}")
    logger.info(f"  Errores guardados        : {total_errors}")
    logger.info("=" * 60)


# ── Punto de entrada ─────────────────────────────────────────────────────────

if __name__ == "__main__":
    args        = parse_args()
    date_ranges = build_date_ranges(args)
    run(date_ranges)