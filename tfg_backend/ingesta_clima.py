import re  # Asegúrate de añadir este import al principio del archivo

def ingestar_datos():
    print(f"[{datetime.now(timezone.utc)}] Iniciando proceso de ingesta...")

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron registros en la tabla 'spot'.")
        return

    # Mapeo en memoria para control de duplicados (Soporta el id UUID)
    try:
        clima_existente = supabase.table("clima").select("id", "spot_id", "fecha_hora").data
        mapa_ids = {
            (reg["spot_id"], datetime.fromisoformat(reg["fecha_hora"]).replace(tzinfo=timezone.utc)): reg["id"] 
            for reg in clima_existente
        }
    except Exception as e:
        print("Historial de clima vacío o inaccesible (se asumen nuevas inserciones).")
        mapa_ids = {}

    registros_totales = []

    for spot in spots:
        spot_id = spot["id"]
        nombre = spot["nombre"]
        point_data = spot.get("point")

        if not point_data:
            print(f"⚠️ El spot {nombre} no tiene datos geográficos en la columna 'point'. Saltando...")
            continue

        # --- PARSER INTELIGENTE DE GEOGRAPHY (WKT VS GEOJSON) ---
        try:
            if isinstance(point_data, str):
                # Si Supabase nos devuelve el formato WKT: "POINT(-5.6042 36.0142)"
                # Extraemos los números flotantes con una expresión regular
                match = re.match(r"POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)", point_data, re.IGNORECASE)
                if match:
                    lng = float(match.group(1))
                    lat = float(match.group(2))
                else:
                    raise ValueError("Formato WKT inválido")
            elif isinstance(point_data, dict) and "coordinates" in point_data:
                # Si en algún entorno devuelve estructura GeoJSON
                lng = float(point_data["coordinates"][0])
                lat = float(point_data["coordinates"][1])
            else:
                print(f"⚠️ Formato geográfico no reconocido para el spot {nombre}. Saltando...")
                continue
        except Exception as err:
            print(f"❌ Error al parsear coordenadas del spot {nombre}: {err}")
            continue

        print(f"-> Procesando datos meteorológicos para: {nombre} ({lat}, {lng})")

        datos_mar = consultar_api_maritima(lat, lng)
        datos_met = consultar_api_meteorologica(lat, lng)

        if not datos_mar or not datos_met or "hourly" not in datos_met or "hourly" not in datos_mar:
            print(f"⚠️ Error de respuesta de APIs externas para el spot {nombre}.")
            continue

        hourly_met = datos_met["hourly"]
        hourly_mar = datos_mar["hourly"]
        horas = hourly_met["time"]

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

    # Inserción Masiva con actualización sucesiva
    if registros_totales:
        print(f"Enviando {len(registros_totales)} registros a la tabla 'clima'...")
        try:
            respuesta = supabase.table("clima").upsert(registros_totales).data
            print("¡Sincronización masiva completada con éxito en Supabase!")
            return respuesta
        except Exception as e:
            print("Error en la transacción con Supabase:", e)
    else:
        print("No se generaron registros válidos para insertar.")
