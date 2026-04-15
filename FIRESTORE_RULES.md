# Firestore Security Rules

Para que la app funcione correctamente, debes configurar las reglas de Firestore en tu Firebase Console.

## Pasos:

1. Ve a Firebase Console → Firestore Database → Rules
2. Reemplaza las reglas con esto:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura y escritura a usuarios autenticados
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
  }
}
```

3. Haz click en "Publicar"

## Importante:

- Solo usuarios autenticados pueden leer/escribir
- Esto es seguro para una app de prueba
- Para producción, agregar validaciones más estrictas (ej: solo el creador puede cerrar un partido)
