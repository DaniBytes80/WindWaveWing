from datetime import datetime, timezone
from supabase import create_client
import requests
import os
import json

# --- Conexión a Supabase ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# --- Funciones auxiliares ---
def obtener_spots_desde_supabase():
    try:
        # Usamos la VIEW que devuelve GeoJSON
        respuesta = supabase.table("spot_geojson").select("*").execute()
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

        # --- EXTRAER LAT/LNG DESDE GEOJSON ---
        geo = spot["point"]  # ya es JSON gracias a la VIEW
        lng = geo["coordinates"][0]
        lat = geo["coordinates"][1]

        print(f"-> Procesando datos para el spot: {nombre} ({lat}, {lng})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        print("API Marítima:", datos_mar)
        print("API Meteorológica:", datos_met)

        if not datos_mar or "hourly" not in datos_mar:
            print(f"   No se pudieron obtener datos marítimos para {nombre}")
            continue

        if not datos_met or "hourly" not in datos_met:
            print(f"   No se pudieron obtener datos meteorológicos para {nombre}")
            continue

        hourly_mar = datos_mar["hourly"]
        hourly_met = datos_met["hourly"]

        tiempos = hourly_mar["time"]

        for i in range(len(tiempos)):
            fecha_iso = datetime.fromisoformat(tiempos[i]).astimezone(timezone.utc).isoformat()

            registro = {
                "spot_id": spot_id,
                "fecha_hora": fecha_iso,
                v_viento = hourly_mar["wind_speed_10m"][i] or 0
                d_viento = hourly_mar["wind_direction_10m"][i] or 0
                altura_ola = hourly_mar["wave_height"][i] or 0
                periodo_ola = hourly_mar["wave_period"][i] or 0
                d_ola = hourly_mar["wave_direction"][i] or 0
                
                registro = {
                    "spot_id": spot_id,
                    "fecha_hora": fecha_iso,
                    "velocidad_viento": v_viento,
                    "direccion_viento": f"{d_viento}°",
                    "racha_viento": v_viento * 1.3,
                    "altura_ola": altura_ola,
                    "periodo_ola": periodo_ola,
                    "direccion_ola": f"{d_ola}°",
                    "temperatura": hourly_met["temperature_2m"][i],
                    "humedad": hourly_met["relative_humidity_2m"][i],
                    "probabilidad_lluvia": hourly_met["precipitation_probability"][i],
                }
                "temperatura": hourly_met["temperature_2m"][i],
                "humedad": hourly_met["relative_humidity_2m"][i],
                "probabilidad_lluvia": hourly_met["precipitation_probability"][i],
            }

            registros_totales.append(registro)

    print("Registros generados:", len(registros_totales))

    if registros_totales:
        try:
            print(f"Subiendo {len(registros_totales)} registros a Supabase...")

            supabase.table("clima").upsert(
                registros_totales,
                on_conflict="spot_id,fecha_hora"
            ).execute()

            print("¡Ingesta completada con éxito!")
        except Exception as e:
            print("Error al guardar datos en Supabase:", e)

if __name__ == "__main__":
    ingestar_datos()
