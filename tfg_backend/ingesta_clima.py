from datetime import datetime, timezone
from supabase import create_client, Client # Asegúrate de importar Client
import requests
import os

# --- Conexión a Supabase (sin configuraciones de auth) ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def obtener_spots_desde_supabase():
    try:
        respuesta = supabase.table("spots").select("*").execute()
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


# --- Proceso principal ---
def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando proceso de ingesta de Capa 1 a Capa 2...")

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron spots en la tabla.")
        return

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]
        lat = spot["lat"]
        lng = spot["lng"]

        print(f"-> Procesando datos para el spot: {nombre} ({lat}, {lng})")

        datos_clima = consultar_api_maritima(lat, lng)

        if not datos_clima or "hourly" not in datos_clima:
            print(f"   No se pudieron obtener datos para {nombre}")
            continue

        hourly = datos_clima["hourly"]
        tiempos = hourly["time"]

        for i in range(len(tiempos)):
            fecha_iso = datetime.fromisoformat(tiempos[i]).astimezone(timezone.utc).isoformat()

            registro = {
                "spot_id": spot_id,
                "fecha_hora": fecha_iso,
                "velocidad_viento": hourly["wind_speed_10m"][i],
                "direccion_viento": f"{hourly['wind_direction_10m'][i]}°",
                "racha_viento": hourly["wind_speed_10m"][i] * 1.3,
                "altura_ola": hourly["wave_height"][i],
                "periodo_ola": hourly["wave_period"][i],
                "direccion_ola": f"{hourly['wave_direction'][i]}°",
                "probabilidad_lluvia": 0.0,
            }

            registros_totales.append(registro)

    if registros_totales:
        try:
            print(f"Subiendo {len(registros_totales)} registros meteorológicos a Supabase...")
            # Usa upsert con on_conflict como string separado por comas
            supabase.table("clima").upsert(
                registros_totales,
                on_conflict="spot_id,fecha_hora"  # Como string, no lista
            ).execute()
            print("¡Ingesta completada con éxito!")
        except Exception as e:
            print("Error al guardar datos en Supabase:", e)
            # Imprime el error detallado
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    ingestar_datos()   
