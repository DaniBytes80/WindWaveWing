from datetime import datetime, timezone
from supabase import create_client
import requests
import os

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def obtener_spots_desde_supabase():
    try:
        res = supabase.table("spot").select("*").data
        print(f"[DEBUG] Spots recuperados de la BD: {len(res) if res else 0}")
        return res
    except Exception as e:
        print("[ERROR] Fallo al obtener spots:", e)
        return []

def consultar_api_maritima(lat, lng):
    url = f"https://marine-api.open-meteo.com/v1/marine?latitude={lat}&longitude={lng}&hourly=wave_height,wave_direction,wave_period,wind_speed_10m,wind_direction_10m"
    try:
        respuesta = requests.get(url)
        if respuesta.status_code != 200:
            print(f"[DEBUG] API Marítima HTTP {respuesta.status_code}")
            return None
        return respuesta.json()
    except Exception as e:
        return None

def consultar_api_meteorologica(lat, lng):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&hourly=temperature_2m,relative_humidity_2m,precipitation_probability"
    try:
        respuesta = requests.get(url)
        if respuesta.status_code != 200:
            print(f"[DEBUG] API Met HTTP {respuesta.status_code}")
            return None
        return respuesta.json()
    except Exception as e:
        return None

def ingestar_datos():
    print(f"[{datetime.now(timezone.utc)}] Iniciando depuración de ingesta...")

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("[ALERTA] La lista de spots está vacía. El bucle no llegará a ejecutarse.")
        return

    try:
        clima_existente = supabase.table("clima").select("id", "spot_id", "fecha_hora").data
        print(f"[DEBUG] Registros preexistentes en la tabla 'clima': {len(clima_existente) if clima_existente else 0}")
        mapa_ids = {
            (reg["spot_id"], datetime.fromisoformat(reg["fecha_hora"]).replace(tzinfo=timezone.utc)): reg["id"] 
            for reg in clima_existente
        }
    except Exception as e:
        print("[DEBUG] No se pudo mapear el histórico (puede estar vacío):", e)
        mapa_ids = {}

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]
        
        # Extracción geográfica
        coords = spot["point"]["coordinates"]
        lng, lat = coords[0], coords[1]

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        if not datos_mar or not datos_met or "hourly" not in datos_met or "hourly" not in datos_mar:
            print(f"[DEBUG] Salto de spot '{nombre}' por falta de respuesta de APIs externas.")
            continue

        hourly_met = datos_met["hourly"]
        hourly_mar = datos_mar["hourly"]
        horas = hourly_met["time"]

        print(f"[DEBUG] Procesando {len(horas)} horas de pronóstico para el spot: {nombre}")

        for i, hora_str in enumerate(horas):
            dt_objeto = datetime.fromisoformat(hora_str).replace(tzinfo=timezone.utc)
            fecha_iso = dt_objeto.isoformat()

            registro = {
                "spot_id": spot_id,
                "fecha_hora": fecha_iso,
                "temperature": hourly_met["temperature_2m"][i],
                "humidity": hourly_met["relative_humidity_2m"][i],
                "precipitation_probability": hourly_met["precipitation_probability"][i],
                "wind_speed": hourly_mar["wind_speed_10m"][i],
                "wind_direction": hourly_mar["wind_direction_10m"][i],
                "wave_height": hourly_mar["wave_height"][i],
                "wave_period": hourly_mar["wave_period"][i],
                "wave_direction": hourly_mar["wave_direction"][i]
            }

            clave_busqueda = (spot_id, dt_objeto)
            if clave_busqueda in mapa_ids:
                registro["id"] = mapa_ids[clave_busqueda]

            registros_totales.append(registro)

    print(f"[DEBUG] Total de registros preparados para enviar: {len(registros_totales)}")

    if registros_totales:
        print(f"Enviando lote a Supabase...")
        try:
            # Forzamos captura de la respuesta cruda para auditar qué responde el servidor
            objeto_respuesta = supabase.table("clima").upsert(registros_totales).data
            print(f"[RESULTADO SUPABASE] Objeto devuelto: {objeto_respuesta}")
            
            if objeto_respuesta is not None and len(objeto_respuesta) == 0:
                print("[💥 ALERTA CRÍTICA] Supabase aceptó la petición pero devolvió 0 filas insertadas. Esto es un síntoma inequívoco de bloqueo por RLS (Row Level Security) o uso de la clave 'anon' incorrecta en GitHub Secrets.")
            else:
                print("¡Registros sincronizados con éxito!")
        except Exception as e:
            print("[ERROR CRÍTICO] La base de datos rechazó la transacción de inmediato:", e)
    else:
        print("[ALERTA] Cero registros construidos. Revisa las coordenadas de los spots.")

if __name__ == "__main__":
    ingestar_datos()
