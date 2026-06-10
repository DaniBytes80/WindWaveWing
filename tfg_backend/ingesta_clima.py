"""
ingesta_clima.py (v2)
=====================
Cambios respecto a v1:
- direccion_viento y direccion_ola ahora se guardan como TEXT (cardinal)
  cuando vienen de AEMET, y como grados cuando vienen de Open-Meteo.
  Se normaliza siempre a grados float para consistencia con la app.
- Corrección de lat/lng: en pointjson GeoJSON el orden es [lng, lat],
  no [lat, lng] como estaba antes.
- Añadido manejo de errores más robusto por spot.
"""

from datetime import datetime, timezone
from supabase import create_client
import requests
import os

SUPABASE_URL              = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
AEMET_API_KEY             = os.getenv("AEMET_API_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ─────────────────────────────────────────────────────────────
#  CONVERSIÓN CARDINAL → GRADOS
#  AEMET devuelve la dirección del viento en cardinal ("N","NE"...)
#  La app y la tabla esperan grados float.
# ─────────────────────────────────────────────────────────────
CARDINAL_A_GRADOS = {
    "N": 0.0, "NNE": 22.5, "NE": 45.0, "ENE": 67.5,
    "E": 90.0, "ESE": 112.5, "SE": 135.0, "SSE": 157.5,
    "S": 180.0, "SSO": 202.5, "SO": 225.0, "OSO": 247.5,
    "O": 270.0, "ONO": 292.5, "NO": 315.0, "NNO": 337.5,
    # inglés (OpenWeather por si acaso)
    "NNW": 337.5, "NW": 315.0, "WNW": 292.5, "W": 270.0,
    "WSW": 247.5, "SW": 225.0, "SSW": 202.5,
    "C": 0.0,  # calma
}

def cardinal_a_grados(valor):
    if valor is None:
        return 0.0
    if isinstance(valor, (int, float)):
        return float(valor)
    return CARDINAL_A_GRADOS.get(str(valor).strip().upper(), 0.0)


# ─────────────────────────────────────────────────────────────
#  AEMET por coordenadas
# ─────────────────────────────────────────────────────────────
def consultar_aemet(lat, lon):
    url = (
        f"https://opendata.aemet.es/opendata/api/prediccion/especifica/puntual/"
        f"latitud/{lat}/longitud/{lon}?api_key={AEMET_API_KEY}"
    )
    try:
        r = requests.get(url, timeout=15).json()
        if "datos" not in r:
            return None
        datos = requests.get(r["datos"], timeout=15).json()
        return datos[0]
    except Exception as e:
        print(f"  Error AEMET: {e}")
        return None


# ─────────────────────────────────────────────────────────────
#  Open-Meteo terrestre
# ─────────────────────────────────────────────────────────────
def consultar_openmeteo_terrestre(lat, lon):
    url = (
        "https://api.open-meteo.com/v1/forecast?"
        f"latitude={lat}&longitude={lon}"
        "&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,"
        "wind_speed_10m,wind_direction_10m,wind_gusts_10m"
        "&wind_speed_unit=kn"
        "&timezone=UTC"
        "&forecast_days=7"
    )
    try:
        return requests.get(url, timeout=15).json()
    except Exception as e:
        print(f"  Error Open-Meteo terrestre: {e}")
        return None


# ─────────────────────────────────────────────────────────────
#  Open-Meteo Marine (olas)
# ─────────────────────────────────────────────────────────────
def consultar_openmeteo_marine(lat, lon):
    url = (
        "https://marine-api.open-meteo.com/v1/marine?"
        f"latitude={lat}&longitude={lon}"
        "&hourly=wave_height,wave_direction,wave_period"
        "&timezone=UTC"
        "&forecast_days=7"
    )
    try:
        return requests.get(url, timeout=15).json()
    except Exception as e:
        print(f"  Error Open-Meteo marine: {e}")
        return None


# ─────────────────────────────────────────────────────────────
#  Puertos del Estado (estructura lista para implementar)
# ─────────────────────────────────────────────────────────────
def consultar_puertos_estado(id_boya):
    if not id_boya:
        return None
    try:
        # TODO: implementar cuando tengas el endpoint
        # url = f"https://opendata.puertos.es/.../boyas/{id_boya}"
        return None
    except Exception as e:
        print(f"  Error Puertos del Estado: {e}")
        return None


# ─────────────────────────────────────────────────────────────
#  Obtener spots de Supabase
# ─────────────────────────────────────────────────────────────
def obtener_spots():
    try:
        r = supabase.table("spot").select("id,nombre,pointjson,id_boya").execute()
        return r.data
    except Exception as e:
        print(f"Error obteniendo spots: {e}")
        return []


# ─────────────────────────────────────────────────────────────
#  PROCESO PRINCIPAL
# ─────────────────────────────────────────────────────────────
def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando ingesta de spots...")

    spots = obtener_spots()
    if not spots:
        print("No hay spots.")
        return

    registros = []

    for spot in spots:
        sid    = spot["id"]
        nombre = spot["nombre"]
        geo    = spot["pointjson"]
        id_boya = spot.get("id_boya")

        if not geo or "coordinates" not in geo:
            print(f"  Spot sin coordenadas: {nombre}")
            continue

        # ✅ FIX: GeoJSON es [lng, lat], no [lat, lng]
        lng = geo["coordinates"][0]
        lat = geo["coordinates"][1]

        print(f"  Procesando {nombre} ({lat:.4f}, {lng:.4f})")

        datos_aemet   = consultar_aemet(lat, lon=lng)
        datos_om      = consultar_openmeteo_terrestre(lat, lon=lng)
        datos_marine  = consultar_openmeteo_marine(lat, lon=lng)
        datos_puertos = consultar_puertos_estado(id_boya)

        if not datos_om or "hourly" not in datos_om:
            print(f"  Open-Meteo no disponible para {nombre}, saltando.")
            continue

        hourly  = datos_om["hourly"]
        tiempos = hourly["time"]

        # ── AEMET: extracción (datos diarios, se aplican a todas las horas del día)
        viento_aemet = None
        racha_aemet  = None
        dir_aemet    = None
        temp_aemet   = None
        hum_aemet    = None
        lluvia_aemet = None

        if datos_aemet:
            try:
                dia0 = datos_aemet["prediccion"]["dia"][0]
                if "viento" in dia0 and dia0["viento"]:
                    viento_aemet = dia0["viento"][0].get("velocidad")
                    dir_aemet    = cardinal_a_grados(dia0["viento"][0].get("direccion"))
                if "rachaMax" in dia0 and dia0["rachaMax"]:
                    racha_aemet  = dia0["rachaMax"][0].get("value") if isinstance(dia0["rachaMax"], list) else dia0["rachaMax"]
                if "temperatura" in dia0 and "dato" in dia0["temperatura"]:
                    temp_aemet   = dia0["temperatura"]["dato"][0].get("value")
                if "humedadRelativa" in dia0 and "dato" in dia0["humedadRelativa"]:
                    hum_aemet    = dia0["humedadRelativa"]["dato"][0].get("value")
                if "probPrecipitacion" in dia0 and dia0["probPrecipitacion"]:
                    lluvia_aemet = dia0["probPrecipitacion"][0].get("value")
            except Exception as e:
                print(f"  Error parseando AEMET para {nombre}: {e}")

        marine_hourly = datos_marine.get("hourly") if datos_marine else None

        for i, tiempo in enumerate(tiempos):
            fecha_iso = datetime.fromisoformat(tiempo).astimezone(timezone.utc).isoformat()

            # Open-Meteo terrestre
            temp_om   = hourly["temperature_2m"][i]
            hum_om    = hourly["relative_humidity_2m"][i]
            lluvia_om = hourly["precipitation_probability"][i]
            viento_om = hourly["wind_speed_10m"][i]
            dir_om    = hourly["wind_direction_10m"][i]
            racha_om  = hourly["wind_gusts_10m"][i]

            # Fusión AEMET (primera hora del día) + Open-Meteo
            temperatura      = float(temp_aemet   if temp_aemet   is not None else (temp_om   or 0))
            humedad          = float(hum_aemet    if hum_aemet    is not None else (hum_om    or 0))
            prob_lluvia      = float(lluvia_aemet if lluvia_aemet is not None else (lluvia_om or 0))
            velocidad_viento = float(viento_aemet if viento_aemet is not None else (viento_om or 0))
            racha_viento     = float(racha_aemet  if racha_aemet  is not None else (racha_om  or 0))
            direccion_viento = float(dir_aemet    if dir_aemet    is not None else (dir_om    or 0))

            # Olas: Puertos del Estado > Open-Meteo Marine
            altura_ola    = 0.0
            periodo_ola   = 0.0
            direccion_ola = 0.0

            if datos_puertos:
                pass  # TODO: implementar cuando tengas el endpoint

            if marine_hourly:
                try:
                    altura_ola    = float(marine_hourly["wave_height"][i]    or 0)
                    periodo_ola   = float(marine_hourly["wave_period"][i]    or 0)
                    direccion_ola = float(marine_hourly["wave_direction"][i] or 0)
                except Exception:
                    pass

            registros.append({
                "spot_id":           sid,
                "fecha_hora":        fecha_iso,
                "velocidad_viento":  velocidad_viento,
                "direccion_viento":  direccion_viento,
                "racha_viento":      racha_viento,
                "altura_ola":        altura_ola,
                "periodo_ola":       periodo_ola,
                "direccion_ola":     direccion_ola,
                "temperatura":       temperatura,
                "humedad":           humedad,
                "probabilidad_lluvia": prob_lluvia,
            })

    print(f"\nTotal registros: {len(registros)}")

    if registros:
        supabase.table("clima").upsert(
            registros,
            on_conflict="spot_id,fecha_hora"
        ).execute()
        print("¡Ingesta de spots completada!")


if __name__ == "__main__":
    ingestar_datos()
