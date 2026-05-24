from datetime import datetime, timezone
from supabase import create_client
import requests
import os

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
AEMET_API_KEY = os.getenv("AEMET_API_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ---------------------------
# AEMET por coordenadas
# ---------------------------
def consultar_aemet(lat, lon):
    url = (
        f"https://opendata.aemet.es/opendata/api/prediccion/especifica/puntual/"
        f"latitud/{lat}/longitud/{lon}?api_key={AEMET_API_KEY}"
    )
    try:
        r = requests.get(url).json()
        if "datos" not in r:
            return None
        datos_url = r["datos"]
        datos = requests.get(datos_url).json()
        return datos[0]  # primer bloque
    except Exception as e:
        print("Error AEMET:", e)
        return None

# ---------------------------
# Open-Meteo terrestre
# ---------------------------
def consultar_openmeteo_terrestre(lat, lon):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}"
        "&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,"
        "wind_speed_10m,wind_direction_10m,wind_gusts_10m"
    )
    try:
        return requests.get(url).json()
    except Exception as e:
        print("Error Open-Meteo terrestre:", e)
        return None

# ---------------------------
# Open-Meteo Marine (olas)
# ---------------------------
def consultar_openmeteo_marine(lat, lon):
    url = (
        "https://marine-api.open-meteo.com/v1/marine?"
        f"latitude={lat}&longitude={lon}"
        "&hourly=wave_height,wave_direction,wave_period"
    )
    try:
        return requests.get(url).json()
    except Exception as e:
        print("Error Open-Meteo marine:", e)
        return None

# ---------------------------
# Puertos del Estado (olas por boya)
# ---------------------------
def consultar_puertos_estado(id_boya):
    """
    Aquí debes conectar con la API oficial de Puertos del Estado usando id_boya.
    Dejo la estructura preparada para que, cuando tengas el endpoint exacto,
    solo completes la URL y el parseo.
    """
    if not id_boya:
        return None

    try:
        # EJEMPLO DE ESTRUCTURA (AJUSTAR A LA API REAL):
        # url = f"https://opendata.puertos.es/.../boyas/{id_boya}"
        # r = requests.get(url).json()
        # return {
        #     "altura_ola": ...,
        #     "periodo_ola": ...,
        #     "direccion_ola": ...
        # }
        return None  # por ahora, sin implementación real
    except Exception as e:
        print("Error Puertos del Estado:", e)
        return None

# ---------------------------
# Obtener spots
# ---------------------------
def obtener_spots():
    try:
        r = supabase.table("spot").select("id,nombre,pointjson,id_boya").execute()
        return r.data
    except Exception as e:
        print("Error obteniendo spots:", e)
        return []

# ---------------------------
# Proceso principal
# ---------------------------
def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando ingesta...")

    spots = obtener_spots()
    if not spots:
        print("No hay spots.")
        return

    registros = []

    for spot in spots:
        sid = spot["id"]
        nombre = spot["nombre"]
        geo = spot["pointjson"]
        id_boya = spot.get("id_boya")

        if not geo or "coordinates" not in geo:
            print(f"Spot sin coordenadas: {nombre}")
            continue

        lat = geo["coordinates"][0]
        lon = geo["coordinates"][1]

        print(f"Procesando {nombre} ({lat}, {lon})")

        datos_aemet = consultar_aemet(lat, lon)
        datos_om = consultar_openmeteo_terrestre(lat, lon)
        datos_marine = consultar_openmeteo_marine(lat, lon)
        datos_puertos = consultar_puertos_estado(id_boya)

        if not datos_om or "hourly" not in datos_om:
            print("Open-Meteo terrestre no disponible, saltando spot.")
            continue

        hourly = datos_om["hourly"]
        tiempos = hourly["time"]

        # -------- AEMET: extracción básica (simplificada) --------
        viento_aemet = None
        racha_aemet = None
        dir_aemet = None
        temp_aemet = None
        hum_aemet = None
        lluvia_aemet = None

        if datos_aemet:
            try:
                dia0 = datos_aemet["prediccion"]["dia"][0]
                # OJO: esto depende del formato exacto de AEMET; aquí simplificamos
                # y usamos el primer dato disponible como referencia diaria.
                if "viento" in dia0 and dia0["viento"]:
                    viento_aemet = dia0["viento"][0].get("velocidad")
                    dir_aemet = dia0["viento"][0].get("direccion")
                if "rachaMax" in dia0:
                    racha_aemet = dia0["rachaMax"]
                if "temperatura" in dia0 and "dato" in dia0["temperatura"]:
                    temp_aemet = dia0["temperatura"]["dato"][0].get("value")
                if "humedadRelativa" in dia0 and "dato" in dia0["humedadRelativa"]:
                    hum_aemet = dia0["humedadRelativa"]["dato"][0].get("value")
                if "probPrecipitacion" in dia0 and dia0["probPrecipitacion"]:
                    lluvia_aemet = dia0["probPrecipitacion"][0].get("value")
            except Exception as e:
                print("Error parseando AEMET:", e)

        # -------- Open-Meteo Marine: olas por hora --------
        marine_hourly = None
        if datos_marine and "hourly" in datos_marine:
            marine_hourly = datos_marine["hourly"]

        for i in range(len(tiempos)):
            fecha_iso = datetime.fromisoformat(tiempos[i]).astimezone(timezone.utc).isoformat()

            # Open-Meteo terrestre
            temp_om = hourly["temperature_2m"][i]
            hum_om = hourly["relative_humidity_2m"][i]
            lluvia_om = hourly["precipitation_probability"][i]
            viento_om = hourly["wind_speed_10m"][i]
            dir_om = hourly["wind_direction_10m"][i]
            racha_om = hourly["wind_gusts_10m"][i]

            # Fusión AEMET + Open-Meteo (sin NULL, siempre número)
            temperatura = (temp_aemet if temp_aemet is not None else temp_om) or 0
            humedad = (hum_aemet if hum_aemet is not None else hum_om) or 0
            prob_lluvia = (lluvia_aemet if lluvia_aemet is not None else lluvia_om) or 0

            velocidad_viento = (viento_aemet if viento_aemet is not None else viento_om) or 0
            racha_viento = (racha_aemet if racha_aemet is not None else racha_om) or 0
            direccion_viento = (dir_aemet if dir_aemet is not None else dir_om) or 0

            # Olas: prioridad Puertos del Estado > Open-Meteo Marine > 0
            altura_ola = 0
            periodo_ola = 0
            direccion_ola = 0

            # Puertos del Estado (si lo implementas y devuelve datos horarios)
            if datos_puertos:
                # Aquí iría la lógica para casar la hora con el dato de la boya
                pass

            # Open-Meteo Marine como respaldo
            if marine_hourly:
                try:
                    altura_ola = marine_hourly["wave_height"][i] or altura_ola
                    periodo_ola = marine_hourly["wave_period"][i] or periodo_ola
                    direccion_ola = marine_hourly["wave_direction"][i] or direccion_ola
                except Exception:
                    pass

            registros.append({
                "spot_id": sid,
                "fecha_hora": fecha_iso,
                "velocidad_viento": float(velocidad_viento or 0),
                "direccion_viento": float(direccion_viento or 0),
                "racha_viento": float(racha_viento or 0),
                "altura_ola": float(altura_ola or 0),
                "periodo_ola": float(periodo_ola or 0),
                "direccion_ola": float(direccion_ola or 0),
                "temperatura": float(temperatura or 0),
                "humedad": float(humedad or 0),
                "probabilidad_lluvia": float(prob_lluvia or 0),
            })

    print("Registros generados:", len(registros))

    if registros:
        supabase.table("clima").upsert(
            registros,
            on_conflict="spot_id,fecha_hora"
        ).execute()
        print("¡Ingesta completada!")

if __name__ == "__main__":
    ingestar_datos()
