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
        return supabase.table("spot").select("*").data
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

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron registros en la tabla 'spot'.")
        return

    # 1. MAPEO ROBUSTO CON OBJETOS DATETIME (Soporta UUID en la columna id)
    try:
        clima_existente = supabase.table("clima").select("id", "spot_id", "fecha_hora").data
        
        # Al parsear la fecha de la BD con fromisoformat(), garantizamos compatibilidad total de zonas horarias
        mapa_ids = {
            (reg["spot_id"], datetime.fromisoformat(reg["fecha_hora"]).replace(tzinfo=timezone.utc)): reg["id"] 
            for reg in clima_existente
        }
    except Exception as e:
        print("Error consultando registros existentes de clima:", e)
        mapa_ids = {}

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]

        coords = spot["point"]["coordinates"]
        lng, lat = coords[0], coords[1]

        print(f"-> Procesando datos para el spot: {nombre}")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        if not datos_mar or not datos_met or "hourly" not in datos_met or "hourly" not in datos_mar:
            continue

        hourly_met = datos_met["hourly"]
        hourly_mar = datos_mar["hourly"]

        horas = hourly_met["time"]

        for i, hora_str in enumerate(horas):
            # Convertimos la hora de la API a un objeto datetime nativo en UTC
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

            # 2. COMPARACIÓN SEMÁNTICA DE CLAVES
            # Buscamos usando el objeto datetime, ignorando discrepancias de formato string
            clave_busqueda = (spot_id, dt_objeto)
            if clave_busqueda in mapa_ids:
                # Si existe, inyectamos el UUID correspondiente para que Supabase ejecute un UPDATE
                registro["id"] = mapa_ids[clave_busqueda]

            registros_totales.append(registro)

    # 3. Transmisión Atómica del Incremento del Sprint
    if registros_totales:
        print(f"Enviando {len(registros_totales)} registros a la tabla 'clima'...")
        try:
            # Los registros con clave 'id' conteniendo un UUID se actualizarán sucesivamente.
            # Los que no la tengan, se insertarán y Supabase les asignará un gen_random_uuid() nativo.
            respuesta = supabase.table("clima").upsert(registros_totales).data
            print("¡Sincronización y actualización sucesiva (UUID) completadas con éxito!")
            return respuesta
        except Exception as e:
            print("Error durante la transacción 'upsert' en Supabase:", e)
    else:
        print("No se consolidaron registros válidos.")

if __name__ == "__main__":
    ingestar_datos()
