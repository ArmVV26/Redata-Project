import requests
import time
import logging
from config import BASE_URL

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


"""
Llama a un endpoint de REData y devuelve el JSON completo.
Devuelve None si la llamada falla para no interrumpir el proceso completo.
"""
def fetch_endpoint(
        url_path: str, start_date: str, end_date: str, extra_params: dict, time_trunc: str = "month"
    ) -> dict | None:

    url = f"{BASE_URL}/{url_path}"
    params = {
        "start_date": start_date,
        "end_date":   end_date,
        "time_trunc": time_trunc,
        **extra_params
    }

    try:
        prepared_url = requests.Request("GET", url, params=params).prepare()
        logger.info(f"  GET {url_path} | {start_date[:4]}")
        logger.info(f"  URL: {prepared_url.url}")

        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        time.sleep(1.5) 
        return response.json()

    except requests.exceptions.HTTPError as e:
        logger.error(f"  HTTP error {e.response.status_code} en {url_path} ({start_date[:4]}): {e}")
        return None
    except requests.exceptions.RequestException as e:
        logger.error(f"  Error de conexión en {url_path} ({start_date[:4]}): {e}")
        return None