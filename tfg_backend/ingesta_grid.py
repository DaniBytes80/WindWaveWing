"""
ingesta_grid.py
===============
Genera un grid meteorológico global para las capas visuales
del mapa (viento, olas, lluvia, temperatura).

Ejecutado por GitHub Actions cada 4 horas.
Los datos se guardan en la tabla `clima_grid` de Supabase.

Grid: puntos cada 2.5° lat/lng cubriendo el mundo completo
→ ~10.000 puntos, suficiente para interpolar un heatmap suave.
"""

from datetime import datetime, timezone
from supabase import create_client
import requests
import os
import time

SUPABASE_URL             = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ─────────────────────────────────────────────────────────────
#  GRID DE PUNTOS
#  Paso de 2.5° → ~10.000 puntos globales
#  Para zonas de interés (España, Mediterráneo, Atlántico norte)
#  se puede reducir a 1° en un segundo paso si hace falta.
# ─────────────────────────────────────────────────────────────
def generar_grid(paso_lat=2.5, paso_lng=2.5):
    puntos = []
    lat = -85.0
    while lat <= 85.0:
        lng = -180.0
        while lng <= 180.0:
            puntos.append((round(lat, 2), round(lng, 2)))
            lng += paso_lng
        lat += paso_lat
    return puntos


# ─────────────────────────────────────────────────────────────
#  OPEN-METEO WEATHER (temperatura, viento, lluvia)
#  Usamos la API batch de Open-Meteo para pedir múltiples
#  coordenadas en una sola petición → mucho más eficiente.
#  Límite: 100 coordenadas por petición.
# ─────────────────────────────────────────────────────────────
def consultar_weather_batch(puntos_chunk):
    """
    puntos_chunk: lista de (lat, lng), máx 100 elementos
    Devuelve: lista de dicts con datos actuales por punto
    """
    lats = ",".join(str(p[0]) for p in puntos_chunk)
    lngs = ",".join(str(p[1]) for p in puntos_chunk)

    url = (
        "https://api.open-meteo.com/v1/forecast"
        f"?latitude={lats}&longitude={lngs}"
        "&current=temperature_2m,wind_speed_10m,wind_direction_10m,"
        "precipitation,wind_gusts_10m"
        "&wind_speed_unit=kn"
        "&timezone=UTC"
        "&forecast_days=1"
    )

    try:
        r = requests.get(url, timeout=30)
        data = r.json()
        # API batch devuelve lista cuando son múltiples puntos
        if isinstance(data, list):
            return data
        elif isinstance(data, dict):
            return [data]   # un solo punto
        return []
    except Exception as e:
        print(f"  Error weather batch: {e}")
        return []


# ─────────────────────────────────────────────────────────────
#  OPEN-METEO MARINE (olas)
#  Solo disponible en zonas oceánicas/costeras.
#  Los puntos de interior simplemente devuelven error → se ignoran.
# ─────────────────────────────────────────────────────────────
def consultar_marine_batch(puntos_chunk):
    lats = ",".join(str(p[0]) for p in puntos_chunk)
    lngs = ",".join(str(p[1]) for p in puntos_chunk)

    url = (
        "https://marine-api.open-meteo.com/v1/marine"
        f"?latitude={lats}&longitude={lngs}"
        "&current=wave_height,wave_direction,wave_period"
        "&timezone=UTC"
        "&forecast_days=1"
    )

    try:
        r = requests.get(url, timeout=30)
        data = r.json()
        if isinstance(data, list):
            return data
        elif isinstance(data, dict):
            return [data]
        return []
    except Exception as e:
        print(f"  Error marine batch: {e}")
        return []


# ─────────────────────────────────────────────────────────────
#  CHUNKS
# ─────────────────────────────────────────────────────────────
def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i + n]


# ─────────────────────────────────────────────────────────────
#  PROCESO PRINCIPAL
# ─────────────────────────────────────────────────────────────
def ingestar_grid():
    print(f"[{datetime.now()}] Iniciando ingesta de grid meteorológico...")

    ahora_utc = datetime.now(timezone.utc).isoformat()
    grid      = generar_grid(paso_lat=2.5, paso_lng=2.5)
    print(f"  Grid generado: {len(grid)} puntos")

    registros  = []
    chunk_size = 100  # máximo de Open-Meteo batch API

    total_chunks = list(chunks(grid, chunk_size))
    print(f"  Procesando {len(total_chunks)} chunks de {chunk_size} puntos...")

    for idx, chunk in enumerate(total_chunks):
        print(f"  Chunk {idx+1}/{len(total_chunks)}...", end=" ", flush=True)

        weather_data = consultar_weather_batch(chunk)
        marine_data  = consultar_marine_batch(chunk)

        # Indexar marine por posición para cruzar con weather
        marine_by_idx = {}
        for i, m in enumerate(marine_data):
            if isinstance(m, dict) and "current" in m:
                marine_by_idx[i] = m["current"]

        for i, punto in enumerate(chunk):
            lat, lng = punto

            # Weather
            w_current = {}
            if i < len(weather_data) and isinstance(weather_data[i], dict):
                w_current = weather_data[i].get("current", {})

            # Marine
            m_current = marine_by_idx.get(i, {})

            registros.append({
                "lat":               lat,
                "lng":               lng,
                "fecha_hora":        ahora_utc,
                "velocidad_viento":  float(w_current.get("wind_speed_10m")   or 0),
                "direccion_viento":  float(w_current.get("wind_direction_10m") or 0),
                "racha_viento":      float(w_current.get("wind_gusts_10m")   or 0),
                "temperatura":       float(w_current.get("temperature_2m")   or 0),
                "precipitacion":     float(w_current.get("precipitation")    or 0),
                "altura_ola":        float(m_current.get("wave_height")      or 0),
                "direccion_ola":     float(m_current.get("wave_direction")   or 0),
                "periodo_ola":       float(m_current.get("wave_period")      or 0),
            })

        print(f"OK ({len(registros)} registros acumulados)")

        # Pausa entre chunks para no saturar Open-Meteo
        time.sleep(0.5)

    print(f"\nTotal registros: {len(registros)}")

    # ── Subir a Supabase en batches de 500 ───────────────────
    if registros:
        print("Subiendo a Supabase tabla clima_grid...")

        # Borrar datos anteriores primero (solo guardamos el snapshot actual)
        supabase.table("clima_grid").delete().neq("lat", 999).execute()

        for batch in chunks(registros, 500):
            supabase.table("clima_grid").insert(batch).execute()
            print(f"  Insertados {len(batch)} registros")

        print("¡Ingesta de grid completada!")


if __name__ == "__main__":
    ingestar_grid()