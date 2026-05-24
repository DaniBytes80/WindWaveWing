from datetime import datetime, timezone
from supabase import create_client
import requests
import os

# --- Conexión a Supabase ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# --- Funciones auxiliares ---
def obtener_spots_desde_supabase():
    try:
        respuesta = supabase.table("spot").select("*").execute()
        return respuesta.data
    except Exception as e:
        print("Error obteniendo spots:", e)
        return []

def consultar_api_maritima(lat, lng):
    url = (
        "https://marine-api.open-meteo.com/v1/marine?"
        f"latitude={lat}&longitude={lng}&hourly=wave_height,wave_direction,wave_period,"
        "wind_speed_10m,wind_direction_10m"
    )
    try:
        respuesta = requests.get(url)
        return respuesta.json()
    except Exception as e:
        print("Error consultando API marítima:", e)
        return None

def consultar_api_meteorologica(lat, lng):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lng}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability"
    )
    try:
        respuesta = requests.get(url)
        return respuesta.json()
    except Exception as e:
        print("Error consultando API meteorológica:", e)
        return None

# --- Proceso principal ---
def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando proceso de ingesta...")

    spots = obtener_spots_desde_supabase()
    print("Spots encontrados:", spots)

    if not spots:
        print("No se encontraron spots en la tabla.")
        return

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]

        # --- EXTRAER LAT/LNG DESDE GEOGRAPHY ---
        coords = spot["point"]["coordinates"]
        lng = coords[0]
        lat = coords[1]

        print(f"-> Procesando datos para el spot: {nombre} ({lat}, {lng})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar
