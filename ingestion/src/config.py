# Rangos anuales: cada tupla es (start, end) de un año completo
DATE_RANGES = [
    ("2018-01-01T00:00", "2019-12-31T23:59"),
    ("2020-01-01T00:00", "2021-12-31T23:59"),
    ("2022-01-01T00:00", "2023-12-31T23:59"),
    ("2024-01-01T00:00", "2025-12-31T23:59"),
]

TIME_TRUNC = "month"

BASE_URL = "https://apidatos.ree.es/es/datos"

# Configuración de llamadas a la API
REQUEST_TIMEOUT        = 30    
SLEEP_BETWEEN_REQUESTS = 2.5   
MAX_RETRIES            = 3     
RETRY_BACKOFF_BASE     = 5     
RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}

# Database y Schema
BRONZE_DATABASE = "PRO_REDATA_BRONZE"
BRONZE_SCHEMA = "RAW"

# Formato: "geo_id": "geo_limit"
GEO_CANDIDATES = {
    "8741": "peninsular",
    "8742": "canarias",
    "8743": "baleares",
    "8744": "ceuta",
    "8745": "melilla",
    "4": "ccaa", # Andalucía
    "5": "ccaa", # Aragón
    "6": "ccaa", # Cantabria
    "7": "ccaa", # Castilla la Mancha
    "8": "ccaa", # Castilla y León
    "9": "ccaa", # Cataluña
    "10": "ccaa", # País Vasco
    "11": "ccaa", # Principado de Asturias
    "13": "ccaa", # Comunidad de Madrid
    "14": "ccaa", # Comunidad de Navarra
    "15": "ccaa", # Comunidad de Valencia
    "16": "ccaa", # Extremadura
    "20": "ccaa", # La Rioja
    "21": "ccaa" # Región de Murcia
}

# Definición de cada endpoint con su tabla destino en Bronze
ENDPOINTS = [
    {
        "name": "balance_electrico",
        "url_path": "balance/balance-electrico",
        "table": "BALANCE_RESPONSE",
        "geo_regions": list(GEO_CANDIDATES.keys()),
        "time_trunc": TIME_TRUNC
    },
    {
        "name": "estructura_generacion",
        "url_path": "generacion/estructura-generacion",
        "table": "GENERATION_RESPONSE",
        "geo_regions": [],
        "time_trunc": TIME_TRUNC
    },
    {
        "name": "componentes-precio-energia-cierre-desglose",
        "url_path": "mercados/componentes-precio-energia-cierre-desglose",
        "table": "MARKET_RESPONSE",
        "geo_regions": [],
        "time_trunc": TIME_TRUNC
    },
]