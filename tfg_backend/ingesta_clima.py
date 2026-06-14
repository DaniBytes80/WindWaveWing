"""
ingesta_clima.py
================
Estrategia:
  - Open-Meteo SIEMPRE: 16 días de previsión horaria para todos los spots
  - Puertos del Estado: complementa con datos reales de boya (últimas horas)
  - AEMET: pendiente de añadir campo id_aemet en tabla spot

Los datos de boya sobreescriben los de Open-Meteo para las horas recientes
gracias al upsert con on_conflict="spot_id,fecha_hora".
"""

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
    try:
        coords = spot["pointjson"]["coordinates"]
        return float(coords[1]), float(coords[0])  # GeoJSON: [lon, lat]
    except Exception:
        return None, None


def guardar_clima(rows):
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


def _valh(h, key, i, default=0.0):
    try:
        v = h.get(key, [])[i]
        return float(v) if v is not None else default
    except Exception:
        return default


def _val(obj, key, default=0.0):
    try:
        v = obj.get(key)
        return float(v) if v is not None else default
    except Exception:
        return default

#  OPEN-METEO — previsión 16 días (base para todos los spots)
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
        h    = r.json().get("hourly", {})
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

#  PUERTOS DEL ESTADO — datos reales de boya (últimas horas)
def obtener_puertos_estado(id_boya, spot_id):
    url = f"https://portus.puertos.es/portussvr/api/v1/boya/{id_boya}/ultimos"
    try:
        r = requests.get(url, timeout=10)
        if r.status_code != 200:
            return []
        rows = []
        for item in r.json():
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
        total_spot = 0

        # PASO 1: Open-Meteo siempre
        rows_om = obtener_openmeteo(lat, lon, spot_id, forecast_days=16)
        if rows_om:
            g = guardar_clima(rows_om)
            total_spot += g
            print(f" Open-Meteo: {g} filas (16 días)")
        else:
            print(f" Open-Meteo sin datos")

        # PASO 2: Boya Puertos del Estado
        if id_boya:
            rows_boya = obtener_puertos_estado(id_boya, spot_id)
            if rows_boya:
                g = guardar_clima(rows_boya)
                total_spot += g
                print(f" Boya {id_boya}: {g} filas (datos reales)")
            else:
                print(f" Boya {id_boya}: sin datos")

        total += total_spot

    print(f"\n Completado. Total: {total} filas")


if __name__ == "__main__":
    ingestar_todos_los_spots()
