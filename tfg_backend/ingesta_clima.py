import os
import requests
from datetime import datetime, timezone, timedelta
from supabase import create_client

SUPABASE_URL              = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
AEMET_API_KEY             = os.getenv("AEMET_API_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

#  UTILIDADES
def _coordenadas(spot):
    """Extrae (lat, lon) del campo pointjson."""
    try:
        coords = spot["pointjson"]["coordinates"]
        # GeoJSON: [longitud, latitud]
        return float(coords[1]), float(coords[0])
    except Exception:
        return None, None


def guardar_clima(rows):
    """Upsert en lotes de 100 filas."""
    if not rows:
        return 0
    guardadas = 0
    for i in range(0, len(rows), 100):
        lote = rows[i:i+100]
        try:
            supabase.table("clima").upsert(
                lote, on_conflict="spot_id,fecha_hora"
            ).execute()
            guardadas += len(lote)
        except Exception as e:
            print(f" Error guardando lote: {e}")
    return guardadas


def _val(obj, key, default=0.0):
    try:
        v = obj.get(key)
        return float(v) if v is not None else default
    except Exception:
        return default

#  FUENTE 1: PUERTOS DEL ESTADO (boya)
def obtener_puertos_estado(id_boya, spot_id):
    """
    Descarga datos de la boya de Puertos del Estado.
    API REST pública: https://www.puertos.es/es-es/oceanografia/
    Devuelve lista de filas o [] si falla.
    """
    url = (
        f"https://portus.puertos.es/portussvr/api/v1/boya"
        f"/{id_boya}/ultimos"
    )
    try:
        r = requests.get(url, timeout=10)
        if r.status_code != 200:
            return []
        data = r.json()
        rows = []
        for item in data:
            try:
                fecha_hora = datetime.fromisoformat(
                    item.get("fecha", "")).replace(tzinfo=timezone.utc)
                rows.append({
                    "spot_id":             spot_id,
                    "fecha_hora":          fecha_hora.isoformat(),
                    "velocidad_viento":    _val(item, "viento_velocidad"),
                    "direccion_viento":    str(item.get("viento_direccion", "0")),
                    "racha_viento":        _val(item, "viento_racha"),
                    "altura_ola":          _val(item, "oleaje_altura_significante"),
                    "periodo_ola":         _val(item, "oleaje_periodo_pico"),
                    "direccion_ola":       str(item.get("oleaje_direccion", "0")),
                    "temperatura":         _val(item, "temperatura_agua"),
                    "humedad":             0.0,
                    "probabilidad_lluvia": 0.0,
                })
            except Exception:
                continue
        return rows
    except Exception as e:
        print(f" Puertos del Estado error: {e}")
        return []

#  FUENTE 2: AEMET
def obtener_aemet(id_aemet, spot_id):
    """
    Descarga predicción horaria de AEMET para un municipio.
    id_aemet: código INE del municipio (ej: "29067" para Málaga)
    """
    if not AEMET_API_KEY or not id_aemet:
        return []
    url = (
        f"https://opendata.aemet.es/opendata/api/prediccion/especifica"
        f"/municipio/horaria/{id_aemet}"
    )
    try:
        r = requests.get(url,
            headers={"api_key": AEMET_API_KEY}, timeout=10)
        if r.status_code != 200:
            return []
        datos_url = r.json().get("datos")
        if not datos_url:
            return []
        r2 = requests.get(datos_url, timeout=10)
        if r2.status_code != 200:
            return []
        prediccion = r2.json()
        rows = []
        for dia in prediccion[0]["prediccion"]["dia"]:
            fecha_base = datetime.strptime(
                dia["fecha"], "%Y-%m-%dT%H:%M:%S").replace(
                tzinfo=timezone.utc)
            # Viento horario
            vientos = {int(v["periodo"]): v for v in dia.get("vientoAndRachaMax", [])}
            # Temperatura horaria
            temps   = {int(t["periodo"]): float(t["value"]) for t in dia.get("temperatura", [])}
            # Lluvia horaria
            lluvias = {int(p["periodo"]): float(p["value"]) for p in dia.get("probPrecipitacion", [])}

            for hora in range(24):
                fecha_hora = fecha_base.replace(hour=hora)
                v = vientos.get(hora, {})
                rows.append({
                    "spot_id":             spot_id,
                    "fecha_hora":          fecha_hora.isoformat(),
                    "velocidad_viento":    float(v.get("velocidad", 0) or 0) * 0.539957,  # km/h → kn
                    "direccion_viento":    str(v.get("direccion", "0")),
                    "racha_viento":        float(v.get("value", 0) or 0) * 0.539957,
                    "altura_ola":          0.0,  # AEMET no da olas
                    "periodo_ola":         0.0,
                    "direccion_ola":       "0",
                    "temperatura":         temps.get(hora, 0.0),
                    "humedad":             0.0,
                    "probabilidad_lluvia": lluvias.get(hora, 0.0),
                })
        return rows
    except Exception as e:
        print(f" AEMET error: {e}")
        return []

#  FUENTE 3: OPEN-METEO
def obtener_openmeteo(lat, lon, spot_id, forecast_days=16):
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude":  lat,
        "longitude": lon,
        "hourly": ",".join([
            "windspeed_10m",
            "winddirection_10m",
            "windgusts_10m",
            "wave_height",
            "wave_period",
            "wave_direction",
            "temperature_2m",
            "relativehumidity_2m",
            "precipitation_probability",
        ]),
        "wind_speed_unit": "kn",
        "forecast_days":   forecast_days,
        "timezone":        "auto",
    }
    try:
        r = requests.get(url, params=params, timeout=15)
        r.raise_for_status()
        data = r.json()
        h    = data.get("hourly", {})
        rows = []
        for i, t in enumerate(h.get("time", [])):
            try:
                fecha_hora = datetime.fromisoformat(t).replace(
                    tzinfo=timezone.utc)
            except Exception:
                continue
            rows.append({
                "spot_id":             spot_id,
                "fecha_hora":          fecha_hora.isoformat(),
                "velocidad_viento":    _valh(h, "windspeed_10m", i),
                "direccion_viento":    str(_valh(h, "winddirection_10m", i, 0)),
                "racha_viento":        _valh(h, "windgusts_10m", i),
                "altura_ola":          _valh(h, "wave_height", i),
                "periodo_ola":         _valh(h, "wave_period", i),
                "direccion_ola":       str(_valh(h, "wave_direction", i, 0)),
                "temperatura":         _valh(h, "temperature_2m", i),
                "humedad":             _valh(h, "relativehumidity_2m", i),
                "probabilidad_lluvia": _valh(h, "precipitation_probability", i),
            })
        return rows
    except Exception as e:
        print(f" Open-Meteo error: {e}")
        return []


def _valh(h, key, i, default=0.0):
    try:
        v = h.get(key, [])[i]
        return float(v) if v is not None else default
    except Exception:
        return default

#  PROCESO PRINCIPAL
def ingestar_todos_los_spots():
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M')}] Ingesta de clima...")

    try:
        r = supabase.table("spot").select(
            "id, nombre, pointjson, id_boya"
        ).execute()
        spots = r.data or []
    except Exception as e:
        print(f" Error obteniendo spots: {e}")
        return

    print(f"  Spots: {len(spots)}")
    total = 0

    for spot in spots:
        spot_id = spot["id"]
        nombre  = spot.get("nombre", spot_id)
        id_boya = spot.get("id_boya")
        lat, lon = _coordenadas(spot)

        if lat is None:
            print(f" {nombre}: sin coordenadas")
            continue

        print(f" {nombre} ({lat:.4f}, {lon:.4f})")
        rows = []
        fuente = ""

        # Prioridad 1: Puertos del Estado 
        if id_boya:
            rows  = obtener_puertos_estado(id_boya, spot_id)
            fuente = f"Puertos del Estado (boya {id_boya})"

        # Prioridad 2: AEMET (si no hay boya) 
        if not rows and AEMET_API_KEY:
            es_espana = -18 <= lon <= 5 and 27 <= lat <= 44
            if es_espana:
                pass

        # Prioridad 3: Open-Meteo 
        if not rows:
            rows   = obtener_openmeteo(lat, lon, spot_id, forecast_days=16)
            fuente = "Open-Meteo (16 días)"

        if not rows:
            print(f" Sin datos de ninguna fuente")
            continue

        guardadas = guardar_clima(rows)
        print(f" {guardadas} filas · {fuente}")
        total += guardadas

    print(f"\n Completado. Total: {total} filas")


if __name__ == "__main__":
    ingestar_todos_los_spots()
