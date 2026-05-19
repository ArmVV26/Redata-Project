import requests
import time
import logging
from config import (
    BASE_URL,
    REQUEST_TIMEOUT,
    SLEEP_BETWEEN_REQUESTS,
    MAX_RETRIES,
    RETRY_BACKOFF_BASE,
    RETRYABLE_STATUS_CODES
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def fetch_endpoint(
        url_path: str,
        start_date: str,
        end_date: str,
        extra_params: dict,
        time_trunc: str = "month"
    ) -> dict | None:
    """
    Llama a un endpoint de REData y devuelve un diccionario con:
    - raw_json
    - http_status_code
    - error_message

    Si la llamada falla, no interrumpe el proceso completo: devuelve raw_json=None
    y guarda la información del error para trazabilidad en Bronze.
    """

    url = f"{BASE_URL}/{url_path}"
    params = {
        "start_date": start_date,
        "end_date":   end_date,
        "time_trunc": time_trunc,
        **extra_params
    }

    year_label = start_date[:7]  # "2024-01" más informativo que solo el año

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            prepared = requests.Request("GET", url, params=params).prepare()
            logger.info(f"  GET {url_path} | {year_label} | intento {attempt}/{MAX_RETRIES}")
            logger.info(f"  URL: {prepared.url}")

            response = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)

            # Si el status es reintentable, lanzamos excepción para entrar en el bloque retry
            if response.status_code in RETRYABLE_STATUS_CODES:
                logger.warning(
                    f"  Status {response.status_code} reintentable en {url_path} "
                    f"({year_label}), intento {attempt}/{MAX_RETRIES}"
                )
                if attempt < MAX_RETRIES:
                    sleep_time = RETRY_BACKOFF_BASE * (2 ** (attempt - 1))  # 5, 10, 20 s
                    logger.info(f"  Esperando {sleep_time}s antes de reintentar…")
                    time.sleep(sleep_time)
                    continue
                else:
                    # Agotados los reintentos → registramos el error en Bronze
                    return {
                        "raw_json":         None,
                        "http_status_code": response.status_code,
                        "error_message":    f"Status {response.status_code} tras {MAX_RETRIES} intentos",
                    }

            response.raise_for_status()  # Lanza HTTPError para otros 4xx

            time.sleep(SLEEP_BETWEEN_REQUESTS)
            logger.info(f"  OK {response.status_code}")

            return {
                "raw_json":         response.json(),
                "http_status_code": response.status_code,
                "error_message":    None,
            }

        except requests.exceptions.HTTPError as e:
            status_code = e.response.status_code if e.response is not None else None
            msg = f"HTTP {status_code}: {e}"
            logger.error(f"  HTTPError en {url_path} ({year_label}): {msg}")
            return {
                "raw_json":         None,
                "http_status_code": status_code,
                "error_message":    msg,
            }

        except requests.exceptions.Timeout:
            msg = f"Timeout tras {REQUEST_TIMEOUT}s, intento {attempt}/{MAX_RETRIES}"
            logger.warning(f"  {msg} en {url_path} ({year_label})")
            if attempt < MAX_RETRIES:
                sleep_time = RETRY_BACKOFF_BASE * (2 ** (attempt - 1))
                logger.info(f"  Esperando {sleep_time}s antes de reintentar…")
                time.sleep(sleep_time)
                continue
            return {
                "raw_json":         None,
                "http_status_code": None,
                "error_message":    f"Timeout tras {MAX_RETRIES} intentos",
            }

        except requests.exceptions.ConnectionError as e:
            msg = f"Error de conexión: {e}"
            logger.error(f"  {msg} en {url_path} ({year_label})")
            # Los errores de conexión no tienen status code
            return {
                "raw_json":         None,
                "http_status_code": None,
                "error_message":    msg,
            }

        except requests.exceptions.RequestException as e:
            msg = f"Error inesperado: {e}"
            logger.error(f"  {msg} en {url_path} ({year_label})")
            return {
                "raw_json":         None,
                "http_status_code": None,
                "error_message":    msg,
            }

    # Nunca debería llegar aquí, pero por seguridad:
    return {
        "raw_json":         None,
        "http_status_code": None,
        "error_message":    "Error desconocido, reintentos agotados",
    }