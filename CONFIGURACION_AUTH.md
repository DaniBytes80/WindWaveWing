# Configuración de Autenticación — WindWaveWing

## 1. ERROR 404 AL CONFIRMAR EMAIL (Supabase)

El enlace de confirmación que Supabase envía por email redirige a una URL.
Si no está configurada, da 404. Pasos:

### En Supabase Dashboard:
1. Ve a **Authentication → URL Configuration**
2. En **Site URL** pon: `windwavewing://auth/callback`
3. En **Redirect URLs** añade:
   - `windwavewing://auth/callback`
   - `http://localhost:3000` (para pruebas web)
4. Guarda cambios

### En AndroidManifest.xml (android/app/src/main/):
Añade dentro del `<activity>` principal:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="windwavewing"
        android:host="auth"
        android:pathPrefix="/callback" />
</intent-filter>
```

### En main.dart — capturar el deep link tras confirmación:
Añade en initState() o en el AuthGate:

```dart
// En main.dart, dentro de initState:
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final session = data.session;
  if (session != null && mounted) {
    // Usuario confirmado y logueado → ir a pantalla principal
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
    );
  }
});
```

---

## 2. GOOGLE SIGN-IN (Error OAuth 401)

### En Google Cloud Console:
1. Ve a **APIs & Services → Credentials**
2. Crea un **OAuth 2.0 Client ID** de tipo **Android**
3. Package name: `com.danibytes.windwavewing` (el que tengas en build.gradle)
4. SHA-1: el que ya tienes configurado
5. Crea también uno de tipo **Web application**
6. Copia el **Web Client ID** (no el de Android)

### En Supabase Dashboard:
1. Ve a **Authentication → Providers → Google**
2. Activa Google
3. En **Client ID**: pega el Web Client ID
4. En **Client Secret**: pega el Web Client Secret
5. Guarda

### En android/app/build.gradle:
```gradle
defaultConfig {
    applicationId "com.danibytes.windwavewing"  // debe coincidir exactamente
    ...
}
```

### En pubspec.yaml (si no está):
```yaml
dependencies:
  google_sign_in: ^6.2.1
```

---

## 3. BIOMETRÍA — Configuración Android

### En android/app/src/main/AndroidManifest.xml:
Añade estos permisos antes de `<application>`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### En pubspec.yaml (si no está):
```yaml
dependencies:
  local_auth: ^2.3.0
  flutter_secure_storage: ^9.2.2
```

### Flujo correcto de biometría con Supabase:
La biometría NO autentica directamente con Supabase.
El flujo correcto es:
1. Usuario hace login normal por primera vez
2. Se guarda el token de Supabase en flutter_secure_storage
3. En siguientes accesos: local_auth verifica huella → si ok, recupera el token guardado
4. Se restaura la sesión con `Supabase.instance.client.auth.recoverSession(token)`

Ver auth_service.dart para la implementación.

---

## 4. VERIFICAR QUE TODO FUNCIONA

Orden de prueba recomendado:
1. Registrar nuevo usuario → verificar que aparece el diálogo de confirmación
2. Abrir email → pulsar enlace → verificar que abre la app (no da 404)
3. Login con email/contraseña → verificar acceso
4. Login Google → verificar (necesita configuración Cloud Console completa)
5. Login biometría → verificar (solo funciona si ya hay sesión guardada)
