# Configuración de Google Sign-In

Esta guía te ayuda a habilitar autenticación con Google en SaleFulbo.

## 1. Crear proyecto en Google Cloud Console

1. Abre [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto nuevo o usa uno existente.
3. Habilita la API de Google Sign-In:
   - Busca "Google Identity" en la barra de búsqueda.
   - Haz clic en "Google Identity Services API" y presiona "Enable".

## 2. Android

### 2a) Obtener SHA1 del debug keystore

```powershell
# Windows (PowerShell)
$keystorePath = "$env:USERPROFILE\.android\debug.keystore"
keytool -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android
```

Busca la línea `SHA1: ...` y copia ese valor.

### 2b) Crear credenciales OAuth

1. En Google Cloud Console, ve a **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**.
2. Selecciona **Android**.
3. Rellena:
   - Package name: `com.salefulbo` (el que tengas en `android/app/build.gradle`)
   - SHA-1: el que copiaste arriba
4. Crea la credencial.
5. Descarga el JSON (no es necesario; las credenciales ya están registradas).

### 2c) Configurar en Android

En `android/app/build.gradle`, asegúrate de tener:

```gradle
defaultConfig {
    applicationId "com.salefulbo"
    minSdkVersion 21
    targetSdkVersion 34
}
```

## 3. Web

### 3a) Crear credenciales OAuth para Web

1. En Google Cloud Console, ve a **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**.
2. Selecciona **Web application**.
3. Añade estos Authorized redirect URIs:
   ```
   http://localhost:5000
   http://localhost:5000/
   https://tudominio.com/ (si tienes hosting)
   ```
4. Copia el **Client ID**.

### 3b) Configurar en Flutter Web

En `web/index.html`, busca la sección `<head>` y añade antes del `</head>`:

```html
<meta name="google-signin-client_id" content="TU_CLIENT_ID.apps.googleusercontent.com">
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

Reemplaza `TU_CLIENT_ID` con el que copiaste.

## 4. iOS (Opcional)

Si necesitas iOS después:

1. Descarga el `GoogleService-Info.plist` de Firebase Console.
2. Añádelo a `ios/Runner` en Xcode.
3. Ve a `ios/Runner/Info.plist` y añade:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.TU_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

## 5. Modo Demo mientras configuras

Mientras configuras Google Sign-In, usa el botón **"Entrar en modo demo"** en la pantalla de login. Esto te permite probar toda la funcionalidad sin Firebase.

## 6. Validación

Una vez configurado:

1. Ejecuta `flutter run -d chrome` (o Android/iOS).
2. Presiona **"Entrar con Google"**.
3. Debería abrir un diálogo de Google.
4. Si ves error, revisa la consola para logs.

## Troubleshooting

- **"Firebase no está configurado"**: Reinicia la app o verifica Firebase Console.
- **Error de OAuth**: Verifica que las URLs/SHA1 sean exactas en Google Cloud.
- **Pop-up bloqueado**: Algunas máquinas bloquean pop-ups; usa el botón en la página.

## Documentación oficial

- [Firebase Auth con Google](https://firebase.flutter.dev/docs/auth/overview/)
- [Google Sign-In package](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com/)
