from datetime import datetime, timezone
from supabase import create_client
import requests
import os

# --- Conexión a Supabase ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

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

def ingestar_datos():
    print(f"[{datetime.now(timezone.utc)}] Iniciando proceso de ingesta...")

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron spots en la tabla.")
        return

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]

        # Extracción desde el tipo GEOGRAPHY de PostGIS [lng, lat]
        coords = spot["point"]["coordinates"]
        lng = coords[0]
        lat = coords[1]

        print(f"-> Procesando datos para el spot: {nombre} ({lat}, {lng})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        if not datos_mar or not datos_met or "hourly" not in datos_met or "hourly" not in datos_mar:
            print(f"Advertencia: Datos incompletos para {nombre}. Saltando...")
            continue

        horas = datos_met["hourly"]["time"]

        for i, hora_str in enumerate(horas):
            # Parsear a formato ISO 8601 compatible con PostgreSQL timestamptz
            dt_objeto = datetime.fromisoformat(hora_str).replace(tzinfo=timezone.utc)

            registro = {
                "spot_id": spot_id,
                "fecha_hora": dt_objeto.isoformat(),
                "temperature": datos_met["hourly"]["temperature_2m"][i],
                "humidity": datos_met["hourly"]["relative_humidity_2m"][i],
                "precipitation_probability": datos_met["hourly"]["precipitation_probability"][i],
                "wind_speed": datos_mar["hourly"]["wind_speed_10m"][i],
                "wind_direction": datos_mar["hourly"]["wind_direction_10m"][i],
                "wave_height": datos_mar["hourly"]["wave_height"][i],
                "wave_period": datos_mar["hourly"]["wave_period"][i],
                "wave_direction": datos_mar["hourly"]["wave_direction"][i]
            }
            registros_totales.append(registro)

    # Inserción masiva con manejo de duplicados (Upsert)
    if registros_totales:
        print(f"Enviando {len(registros_totales)} registros a la tabla 'clima'...")
        try:
            # Recomiendo encarecidamente usar upsert pasándole la restricción única
            respuesta = supabase.table("clima").upsert(
                registros_totales, 
                on_conflict="spot_id,fecha_hora"
            ).execute()
            print("¡Inserción masiva en Supabase completada con éxito!")
        except Exception as e:
            print("Error durante la inserción en Supabase:", e)
    else:
        print("No se generaron registros para insertar.")

if __name__ == "__main__":
    ingestar_datos()
