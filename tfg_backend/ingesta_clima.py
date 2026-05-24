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
        # Eliminado .execute() para resolver el DeprecationWarning
        respuesta = supabase.table("spot").select("*").data
        return respuesta
    except Exception as e:
        print("Error obteniendo datos de la tabla 'spot':", e)
        return []

def consultar_api_maritima(lat, lng):
    url = (
        "https://marine-api.open-meteo.com/v1/marine?"
        f"latitude={lat}&longitude={lng}&hourly=wave_height,wave_direction,wave_period,"
        "wind_speed_10m,wind_direction_10m"
    )
    try:
        respuesta = requests.get(url)
        if respuesta.status_code != 200:
            print(f"Error API Marítima ({respuesta.status_code}): {respuesta.text}")
            return None
        return respuesta.json()
    except Exception as e:
        print("Error en petición HTTP a API marítima:", e)
        return None

def consultar_api_meteorologica(lat, lng):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lng}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability"
    )
    try:
        respuesta = requests.get(url)
        if respuesta.status_code != 200:
            print(f"Error API Meteorológica ({respuesta.status_code}): {respuesta.text}")
            return None
        return respuesta.json()
    except Exception as e:
        print("Error en petición HTTP a API meteorológica:", e)
        return None

def ingestar_datos():
    print(f"[{datetime.now(timezone.utc)}] Iniciando proceso de ingesta...")

    # Comprobación estricta de la tabla de la entidad "spot"
    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron registros en la tabla 'spot'.")
        return

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]

        # Extracción segura de coordenadas desde tipo GEOGRAPHY
        coords = spot["point"]["coordinates"]
        lng, lat = coords[0], coords[1]

        print(f"-> Procesando datos para el spot: {nombre} (ID: {spot_id})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        # Validación estructural robusta para evitar KeyErrors
        if not datos_mar or not datos_met:
            continue
            
        if "hourly" not in datos_met or "hourly" not in datos_mar:
            print(f"⚠️ Error estructural en la respuesta de las APIs para el spot {nombre}.")
            print("Estructura Met disponible:", datos_met.keys())
            print("Estructura Mar disponible:", datos_mar.keys())
            continue

        hourly_met = datos_met["hourly"]
        hourly_mar = datos_mar["hourly"]

        # Verificación explícita de las claves requeridas antes de iterar
        claves_met_ok = all(k in hourly_met for k in ["time", "temperature_2m", "relative_humidity_2m", "precipitation_probability"])
        claves_mar_ok = all(k in hourly_mar for k in ["wind_speed_10m", "wind_direction_10m", "wave_height", "wave_period", "wave_direction"])

        if not claves_met_ok or not claves_mar_ok:
            print(f"⚠️ Columnas horarias ausentes o renombradas por la API en el spot {nombre}.")
            print("Claves Met encontradas:", hourly_met.keys())
            print("Claves Mar encontradas:", hourly_mar.keys())
            continue

        horas = hourly_met["time"]

        for i, hora_str in enumerate(horas):
            dt_objeto = datetime.fromisoformat(hora_str).replace(tzinfo=timezone.utc)

            registro = {
                "spot_id": spot_id,
                "fecha_hora": dt_objeto.isoformat(),
                "temperature": hourly_met["temperature_2m"][i],
                "humidity": hourly_met["relative_humidity_2m"][i],
                "precipitation_probability": hourly_met["precipitation_probability"][i],
                "wind_speed": hourly_mar["wind_speed_10m"][i],
                "wind_direction": hourly_mar["wind_direction_10m"][i],
                "wave_height": hourly_mar["wave_height"][i],
                "wave_period": hourly_mar["wave_period"][i],
                "wave_direction": hourly_mar["wave_direction"][i]
            }
            registros_totales.append(registro)

    # Inserción/Sincronización masiva eliminando .execute()
    if registros_totales:
        print(f"Enviando {len(registros_totales)} registros a la tabla 'clima'...")
        try:
            # Eliminado .execute() para cumplir con las directrices actualizadas del SDK de Supabase
            respuesta = supabase.table("clima").upsert(
                registros_totales, 
                on_conflict="spot_id,fecha_hora"
            ).data
            print("¡Inserción masiva en Supabase completada con éxito!")
            return respuesta
        except Exception as e:
            print("Error en la transacción 'upsert' de Supabase:", e)
    else:
        print("No se consolidaron registros válidos para la tabla 'clima'.")

if __name__ == "__main__":
    ingestar_datos()
