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
        respuesta = supabase.table("spot").select("id,nombre,pointjson").execute()
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
        return requests.get(url).json()
    except:
        return None

def consultar_api_meteorologica(lat, lng):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lng}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability"
    )
    try:
        return requests.get(url).json()
    except:
        return None

# --- Proceso principal ---
def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando proceso de ingesta...")

    spots = obtener_spots_desde_supabase()
    print("Spots encontrados:", spots)

    if not spots:
        print("No se encontraron spots en la tabla.")
        return

    # ⭐ LIMITACIÓN TEMPORAL PARA DESARROLLO
    spots = spots[:2]   # <--- SOLO 2 SPOTS PARA QUE TARDE POQUÍSIMO

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]
        geo = spot["pointjson"]

        if not geo or "coordinates" not in geo:
            print(f"⚠ Spot sin coordenadas válidas: {nombre}. Saltando.")
            continue

        lat = geo["coordinates"][0]
        lng = geo["coordinates"][1]

        print(f"-> Procesando spot: {nombre} ({lat}, {lng})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        if not datos_met or "hourly" not in datos_met:
            print(f"⚠ No hay datos meteorológicos para {nombre}. Saltando.")
            continue

        hourly_met = datos_met["hourly"]

        sin_mar = (
            not datos_mar or
            "hourly" not in datos_mar or
            all(v is None for v in datos_mar["hourly"]["wave_height"])
        )

        hourly_mar = datos_mar["hourly"] if not sin_mar else None

        tiempos = hourly_met["time"]

        for i in range(len(tiempos)):
            fecha_iso = datetime.fromisoformat(tiempos[i]).astimezone(timezone.utc).isoformat()

            temperatura = hourly_met["temperature_2m"][i]
            humedad = hourly_met["relative_humidity_2m"][i]
            prob_lluvia = hourly_met["precipitation_probability"][i]

            if not sin_mar:
                v_viento = hourly_mar["wind_speed_10m"][i]
                d_viento = hourly_mar["wind_direction_10m"][i]
                altura_ola = hourly_mar["wave_height"][i]
                periodo_ola = hourly_mar["wave_period"][i]
                d_ola = hourly_mar["wave_direction"][i]
            else:
                v_viento = None
                d_viento = None
                altura_ola = None
                periodo_ola = None
                d_ola = None

            registro = {
                "spot_id": spot_id,
                "fecha_hora": fecha_iso,
                "velocidad_viento": v_viento,
                "direccion_viento": f"{d_viento}°" if d_viento is not None else None,
                "racha_viento": v_viento * 1.3 if v_viento is not None else None,
                "altura_ola": altura_ola,
                "periodo_ola": periodo_ola,
                "direccion_ola": f"{d_ola}°" if d_ola is not None else None,
                "temperatura": temperatura,
                "humedad": humedad,
                "probabilidad_lluvia": prob_lluvia,
            }

            registros_totales.append(registro)

    print("Registros generados:", len(registros_totales))

    if registros_totales:
        try:
            supabase.table("clima").upsert(
                registros_totales,
                on_conflict="spot_id,fecha_hora"
            ).execute()
            print("¡Ingesta completada con éxito!")
        except Exception as e:
            print("Error al guardar datos en Supabase:", e)

if __name__ == "__main__":
    ingestar_datos()
