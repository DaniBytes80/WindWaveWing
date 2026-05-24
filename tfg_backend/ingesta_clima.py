def ingestar_datos():
    print(f"[{datetime.now(timezone.utc)}] Iniciando proceso de ingesta...")

    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron registros en la tabla 'spot'.")
        return

    # 1. Traemos los registros existentes en la tabla 'clima' para mapear sus IDs actuales
    # Esto evita hacer consultas individuales en el bucle (lo que tumbaría el rendimiento)
    try:
        clima_existente = supabase.table("clima").select("id", "spot_id", "fecha_hora").data
        # Creamos un diccionario indexado por (spot_id, fecha_hora) para búsquedas O(1)
        mapa_ids = {
            (reg["spot_id"], reg["fecha_hora"]): reg["id"] 
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
            # Formateamos la fecha al formato ISO estricto con zona horaria
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

            # 2. COMPROBACIÓN SUCESIVA: ¿Ya existe este spot a esta hora en la base de datos?
            clave_busqueda = (spot_id, fecha_iso)
            if clave_busqueda in mapa_ids:
                # Si existe, le inyectamos su ID actual de la base de datos para que actúe el UPDATE
                registro["id"] = mapa_ids[clave_busqueda]

            registros_totales.append(registro)

    # 3. Inserción Masiva Inteligente
    if registros_totales:
        print(f"Enviando {len(registros_totales)} registros a la tabla 'clima'...")
        try:
            # Al incluir el campo 'id' en los que ya existían, Supabase actualiza. 
            # Los que no llevan 'id' se insertan como nuevos.
            respuesta = supabase.table("clima").upsert(registros_totales).data
            print("¡Sincronización y actualización sucesiva completadas con éxito!")
            return respuesta
        except Exception as e:
            print("Error durante la transacción en Supabase:", e)
    else:
        print("No se consolidaron registros válidos.")
