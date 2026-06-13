import os
import requests
from datetime import datetime, timezone
from supabase import create_client

SUPABASE_URL              = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

#  OPEN-METEO
def obtener_clima_openmeteo(lat, lon, forecast_days=16):
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
        return r.json()
    except Exception as e:
        print(f" Open-Meteo error: {e}")
        return None


def parsear_openmeteo(data, spot_id):
    if not data or "hourly" not in data:
        return []

    h    = data["hourly"]
    rows = []

    for i, t in enumerate(h.get("time", [])):
        try:
            fecha_hora = datetime.fromisoformat(t).replace(tzinfo=timezone.utc)
        except Exception:
            continue

        rows.append({
            "spot_id":             spot_id,
            "fecha_hora":          fecha_hora.isoformat(),
            "velocidad_viento":    _val(h, "windspeed_10m", i),
            "direccion_viento":    str(_val(h, "winddirection_10m", i, 0)),
            "racha_viento":        _val(h, "windgusts_10m", i),
            "altura_ola":          _val(h, "wave_height", i),
            "periodo_ola":         _val(h, "wave_period", i),        
            "direccion_ola":       str(_val(h, "wave_direction", i, 0)),  
            "temperatura":         _val(h, "temperature_2m", i),
            "humedad":             _val(h, "relativehumidity_2m", i),
            "probabilidad_lluvia": _val(h, "precipitation_probability", i),
        })

    return rows


def _val(h, key, i, default=0.0):
    try:
        v = h.get(key, [])[i]
        return float(v) if v is not None else default
    except Exception:
        return default

#  SUPABASE
def guardar_clima(rows):
    if not rows:
        return 0
    guardadas = 0
    for i in range(0, len(rows), 100):
        lote = rows[i:i+100]
        try:
            supabase.table("clima").upsert(
                lote,
                on_conflict="spot_id,fecha_hora"
            ).execute()
            guardadas += len(lote)
        except Exception as e:
            print(f" Error guardando lote: {e}")
    return guardadas

#  PROCESO PRINCIPAL
def ingestar_todos_los_spots():
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M')}] Ingesta de clima...")

    try:
        r = supabase.table("spot").select("id, nombre, latitud, longitud").execute()
        spots = r.data or []
    except Exception as e:
        print(f" Error obteniendo spots: {e}")
        return

    print(f"  Spots: {len(spots)}")
    total = 0

    for spot in spots:
        spot_id = spot["id"]
        nombre  = spot.get("nombre", spot_id)
        lat     = spot.get("latitud")
        lon     = spot.get("longitud")

        if lat is None or lon is None:
            print(f"    {nombre}: sin coordenadas")
            continue

        print(f" {nombre} ({lat}, {lon})")

        data = obtener_clima_openmeteo(lat, lon, forecast_days=16)
        rows = parsear_openmeteo(data, spot_id)

        if not rows:
            print(f" Sin datos")
            continue

        guardadas = guardar_clima(rows)
        print(f" {guardadas} filas ({len(rows)} horas · 16 días)")
        total += guardadas

    print(f"\n Completado. Total: {total} filas")


if __name__ == "__main__":
    ingestar_todos_los_spots()
