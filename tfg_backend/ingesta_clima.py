def ingestar_datos():
    print(f"[{datetime.now()}] Iniciando proceso de ingesta de Capa 1 a Capa 2...")
    
    # 1. Leer los Spots que creaste (La Térmica, Sacaba, etc.)
    spots = obtener_spots_desde_supabase()
    if not spots:
        print("No se encontraron spots en la tabla.")
        return

    registros_totales = []

    # 2. Iterar por cada spot y descargar su clima de predicción
    for spot in spots:
        spot_id = spot['id']
        nombre = spot['nombre']
        
        # ==================================================
        # ¡AQUÍ ESTÁ EL CAMBIO! Usamos 'lat' y 'lng' de tu BD
        # ==================================================
        lat = spot['lat']  
        lng = spot['lng']  
        
        print(f"-> Procesando datos para el spot: {nombre} ({lat}, {lng})")
        
        # Consumo de API
        datos_clima = consultar_api_maritima(lat, lng)
        
        if not datos_clima or "hourly" not in datos_clima:
            print(f"   No se pudieron obtener datos para {nombre}")
            continue
            
        hourly = datos_clima["hourly"]
        tiempos = hourly["time"]
        
        # 3. Formatear y empaquetar el JSON mapeado a nuestra BD
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
                "probabilidad_lluvia": 0.0 
            }
            registros_totales.append(registro)

    # 4. Volcado masivo seguro a Supabase
    if registros_totales:
        try:
            print(f"Subiendo {len(registros_totales)} registros meteorológicos a Supabase...")
            resultado = supabase.table("condiciones_meteorologicas").upsert(
                registros_totales, 
                on_conflict="spot_id,fecha_hora"
            ).execute()
            print("¡Ingesta completada con éxito en la base de datos!")
        except Exception as e:
            print(f"Error al guardar datos en Supabase: {e}")