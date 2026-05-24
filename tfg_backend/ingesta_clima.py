from datetime import datetime, timezone
from supabase import create_client, Client # Asegúrate de importar Client
import requests
import os

# --- Conexión a Supabase (sin configuraciones de auth) ---
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

# ... resto del código (igual) ...

# --- Proceso principal ---
def ingestar_datos():
    # ... código anterior ...

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
