from datetime import datetime, timezone, timedelta
from supabase import create_client
import requests
import os
import json

SUPABASE_URL              = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
FIREBASE_SA_JSON          = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

def _obtener_access_token():
    try:
        import google.auth.transport.requests
        from google.oauth2 import service_account
        sa_info = json.loads(FIREBASE_SA_JSON)
        credentials = service_account.Credentials.from_service_account_info(
            sa_info,
            scopes=["https://www.googleapis.com/auth/firebase.messaging"],
        )
        credentials.refresh(google.auth.transport.requests.Request())
        return credentials.token
    except Exception as e:
        print(f"    ❌ Error token OAuth2: {e}")
        return None


def enviar_push(token_dispositivo, titulo, cuerpo, data=None):
    if not FIREBASE_SA_JSON:
        print("    ⚠️  FIREBASE_SERVICE_ACCOUNT_JSON no configurado")
        return False
    access_token = _obtener_access_token()
    if not access_token:
        return False
    sa_info    = json.loads(FIREBASE_SA_JSON)
    project_id = sa_info.get("project_id")
    url        = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"
    payload = {
        "message": {
            "token": token_dispositivo,
            "notification": {"title": titulo, "body": cuerpo},
            "android": {
                "priority": "HIGH",
                "notification": {"sound": "default"},
            },
            "data": {k: str(v) for k, v in (data or {}).items()},
        }
    }
    try:
        r = requests.post(url, json=payload,
            headers={"Authorization": f"Bearer {access_token}",
                     "Content-Type": "application/json"},
            timeout=10)
        if r.status_code == 200:
            print(f"  Push enviado correctamente")
            return True
        else:
            print(f"  Error FCM: {r.status_code} → {r.text}")
            return False
    except Exception as e:
        print(f"  Error enviando push: {e}")
        return False


# ─────────────────────────────────────────────────────────────
#  DATOS
# ─────────────────────────────────────────────────────────────

def obtener_clima_spot(spot_id):
    try:
        hace_15min = (datetime.now(timezone.utc) - timedelta(minutes=15)).isoformat()
        r = supabase.table("mediciones_estacion") \
            .select("*").eq("spot_id", spot_id) \
            .gte("fecha_hora", hace_15min) \
            .order("fecha_hora", desc=True).limit(1).execute()
        if r.data:
            print(f" Estación propia")
            return r.data[0], "estacion"
    except Exception:
        pass
    try:
        hace_1h = (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat()
        r = supabase.table("clima") \
            .select("*").eq("spot_id", spot_id) \
            .gte("fecha_hora", hace_1h) \
            .order("fecha_hora", desc=True).limit(1).execute()
        if r.data:
            print(f" Tabla clima")
            return r.data[0], "clima"
    except Exception as e:
        print(f" Error clima: {e}")
    return None, None


def obtener_perfil(user_id):
    try:
        r = supabase.table("Perfiles") \
            .select("peso_kg, notificaciones_activas") \
            .eq("id", user_id).limit(1).execute()
        return r.data[0] if r.data else {}
    except Exception:
        return {}


def obtener_materiales(user_id, disciplina):
    try:
        r = supabase.table("MaterialUsuario") \
            .select("*, MaterialDetalle(*)") \
            .eq("user_id", user_id).eq("disciplina", disciplina).execute()
        return r.data or []
    except Exception:
        return []


def obtener_reglas(disciplina, nivel):
    try:
        r = supabase.table("ReglasMaterial") \
            .select("*") \
            .eq("disciplina", disciplina).eq("nivel", nivel).execute()
        return r.data or []
    except Exception:
        return []


def obtener_token_fcm(user_id):
    try:
        r = supabase.table("Dispositivos") \
            .select("token").eq("user_id", user_id) \
            .order("fecha_registro", desc=True).limit(1).execute()
        return r.data[0]["token"] if r.data else None
    except Exception:
        return None


def ya_notificado_reciente(user_id, spot_id, horas=4):
    """Comprueba si ya se notificó en las últimas N horas."""
    try:
        desde = (datetime.now(timezone.utc) - timedelta(hours=horas)).isoformat()
        r = supabase.table("AlertasGeneradas") \
            .select("id").eq("user_id", user_id).eq("spot_id", spot_id) \
            .gte("fecha", desde).execute()
        return len(r.data) > 0
    except Exception:
        return False


def en_horario_util(hora_inicio=7, hora_fin=22):
    """True si la hora actual está en el horario configurado."""
    hora_local = datetime.now().hour
    return hora_inicio <= hora_local < hora_fin


def _en_rango(valor, minimo, maximo):
    if valor is None:
        return True
    try:
        v = float(valor)
        if minimo is not None and v < float(minimo): return False
        if maximo is not None and v > float(maximo): return False
    except Exception:
        return True
    return True


def clima_cumple_regla(clima, regla):
    return all([
        _en_rango(clima.get("velocidad_viento"), regla.get("viento_min"),  regla.get("viento_max")),
        _en_rango(clima.get("altura_ola"),        regla.get("ola_min"),     regla.get("ola_max")),
        _en_rango(clima.get("periodo_ola"),       regla.get("periodo_min"), regla.get("periodo_max")),
    ])


def material_cumple_regla(material, regla, peso_kg):
    if not _en_rango(peso_kg, regla.get("peso_min"), regla.get("peso_max")):
        return False
    detalle = material.get("MaterialDetalle")
    if isinstance(detalle, list):
        detalle = next((d for d in detalle if d is not None), None)
    if not detalle:
        return True
    return all([
        _en_rango(detalle.get("volumen_l"),      regla.get("volumen_min"),     regla.get("volumen_max")),
        _en_rango(detalle.get("superficie_m2"),  regla.get("superficie_min"),  regla.get("superficie_max")),
        _en_rango(detalle.get("mastil_foil_cm"), regla.get("mastil_foil_min"), regla.get("mastil_foil_max")),
        _en_rango(detalle.get("front_cm2"),      regla.get("front_min"),       regla.get("front_max")),
        _en_rango(detalle.get("stab_cm2"),       regla.get("stab_min"),        regla.get("stab_max")),
    ])


def evaluar_combinacion(clima, reglas, materiales, peso_kg):
    print(f"      Peso usuario: {peso_kg}kg")
    print(f"      Reglas disponibles: {len(reglas)}")
    print(f"      Materiales disponibles: {len(materiales)}")
    for regla in reglas:
        clima_ok = clima_cumple_regla(clima, regla)
        print(f"      Regla '{regla.get('descripcion','')}': "
              f"viento {regla.get('viento_min')}-{regla.get('viento_max')}kn "
              f"ola {regla.get('ola_min')}-{regla.get('ola_max')}m "
              f"peso {regla.get('peso_min')}-{regla.get('peso_max')}kg "
              f"→ clima_ok={clima_ok}")
        if not clima_ok:
            continue
        for mat in materiales:
            mat_ok = material_cumple_regla(mat, regla, peso_kg)
            print(f"        Material '{mat.get('nombre','?')}': mat_ok={mat_ok}")
            if mat_ok:
                return mat, regla
    return None, None


def registrar_generada(user_id, spot_id, material_id, mensaje):
    try:
        supabase.table("AlertasGeneradas").insert({
            "user_id":        user_id,
            "spot_id":        spot_id,
            "fecha":          datetime.now(timezone.utc).isoformat(),
            "mensaje":        mensaje,
            "material_usado": material_id,
        }).execute()
    except Exception as e:
        print(f"    Error registrando: {e}")

def evaluar_alertas():
    print(f"\n[{datetime.now().strftime('%Y-%m-%d %H:%M')}] Evaluando alertas...")

    try:
        r = supabase.table("AlertasUsuario").select("*").eq("activa", True).execute()
        alertas = r.data or []
    except Exception as e:
        print(f"Error: {e}"); return

    print(f"  Alertas activas: {len(alertas)}")
    enviadas = 0

    for alerta in alertas:
        user_id         = alerta["user_id"]
        spot_id         = alerta["spot_id"]
        disciplina      = alerta.get("disciplina")
        nivel           = alerta.get("nivel")
        nombre          = alerta.get("nombre", "Sin nombre")
        frecuencia_h    = alerta.get("frecuencia_horas", 4)
        hora_inicio     = alerta.get("hora_inicio", 7)
        hora_fin        = alerta.get("hora_fin", 22)

        print(f"\n  ▶ '{nombre}' | {disciplina}/{nivel} | cada {frecuencia_h}h | {hora_inicio}:00-{hora_fin}:00")

        if not disciplina or not nivel:
            continue

        # ── Horario útil ──────────────────────────────────────
        if not en_horario_util(hora_inicio, hora_fin):
            print(f"   Fuera de horario ({hora_inicio}:00-{hora_fin}:00)")
            continue

        # ── Notificaciones activas en perfil ──────────────────
        perfil = obtener_perfil(user_id)
        if not perfil.get("notificaciones_activas", True):
            print("  Notificaciones desactivadas")
            continue

        # ── Anti-spam con frecuencia configurable ─────────────
        if ya_notificado_reciente(user_id, spot_id, horas=frecuencia_h):
            print(f"  Ya notificado en las últimas {frecuencia_h}h")
            continue

        # ── Clima ─────────────────────────────────────────────
        clima, fuente = obtener_clima_spot(spot_id)
        if not clima:
            print("  Sin datos de clima")
            continue

        viento = clima.get("velocidad_viento", 0)
        ola    = clima.get("altura_ola", 0)
        print(f"    Clima [{fuente}]: {viento}kn · {ola}m")

        # ── Reglas y materiales ───────────────────────────────
        reglas     = obtener_reglas(disciplina, nivel)
        materiales = obtener_materiales(user_id, disciplina)
        peso_kg    = perfil.get("peso_kg")

        if not reglas:
            print(f"  Sin reglas para {disciplina}/{nivel}")
            continue
        if not materiales:
            print(f"  Sin materiales para {disciplina}")
            continue

        material_ok, _ = evaluar_combinacion(clima, reglas, materiales, peso_kg)
        if not material_ok:
            print("  Condiciones o material no válidos")
            continue

        mat_nombre = material_ok.get("nombre") or material_ok.get("modelo", "tu material")
        print(f"  Material válido: {mat_nombre}")

        # ── Token FCM ─────────────────────────────────────────
        token = obtener_token_fcm(user_id)
        if not token:
            print("   Sin token FCM")
            continue

        # ── Mensaje ───────────────────────────────────────────
        msg    = alerta.get("mensaje", "").strip()
        cuerpo = msg if msg else (
            f"{disciplina.capitalize()} · Nivel {nivel}\n"
            f"Viento: {viento:.0f} kn · Ola: {ola:.1f} m\n"
            f"Material: {mat_nombre}")
        titulo = "¡Condiciones perfectas!"

        if enviar_push(token, titulo, cuerpo,
                       data={"spot_id": spot_id, "disciplina": disciplina}):
            registrar_generada(user_id, spot_id, material_ok["id"], cuerpo)
            enviadas += 1

    print(f"\nCompletado. Enviadas: {enviadas}")


if __name__ == "__main__":
    evaluar_alertas()
