# Firebase Cloud Messaging (FCM) — configuração final

O código desta versão já implementa o fluxo solicitado ao time Flutter:

1. `firebase_messaging` e `firebase_core` no `pubspec.yaml`.
2. Pedido de permissão ao usuário.
3. Captura do token com `FirebaseMessaging.instance.getToken()`.
4. Atualização automática quando o token muda (`onTokenRefresh`).
5. Registro opcional após o login:
   - `POST /api/usuarios/fcm-token`
   - JSON: `{"token":"TOKEN_DO_DISPOSITIVO"}`
6. Remoção no logout:
   - `DELETE /api/usuarios/fcm-token`
7. Primeiro plano:
   - `FirebaseMessaging.onMessage`
   - mensagem salva na central de notificações
   - aviso dentro do aplicativo
8. Ao abrir o app por uma notificação:
   - `FirebaseMessaging.onMessageOpenedApp`
   - `FirebaseMessaging.instance.getInitialMessage()`
9. Segundo plano:
   - Android/iOS: handler Dart
   - Web: `firebase-messaging-sw.js`

## O que não pode vir preenchido no ZIP

As credenciais do projeto Firebase pertencem ao projeto do seu time e não podem ser inventadas.

Sem essas credenciais, o RotaFácil continua funcionando normalmente.
Em **Perfil > Notificações**, a tela informa que o Firebase não está configurado.
Também existe o botão **Gerar notificação de teste**, que funciona sem Firebase.

## Chrome / Web

Crie/abra o aplicativo Web do RotaFácil no Firebase Console e obtenha:

- apiKey
- appId
- messagingSenderId
- projectId
- authDomain
- storageBucket
- chave VAPID pública do Cloud Messaging

Execute o app assim no PowerShell:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=SUA_API_KEY `
  --dart-define=FIREBASE_APP_ID=SEU_APP_ID `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=SEU_SENDER_ID `
  --dart-define=FIREBASE_PROJECT_ID=SEU_PROJECT_ID `
  --dart-define=FIREBASE_AUTH_DOMAIN=SEU_AUTH_DOMAIN `
  --dart-define=FIREBASE_STORAGE_BUCKET=SEU_BUCKET `
  --dart-define=FIREBASE_WEB_VAPID_KEY=SUA_CHAVE_VAPID
```

Para notificações em background no Chrome, copie:

```text
web/firebase-messaging-sw.js.example
```

para:

```text
web/firebase-messaging-sw.js
```

e substitua os valores `SEU_...` pelos dados do mesmo projeto Firebase.

## Android

Depois de executar `flutter create .`, adicione ao arquivo:

```text
android/app/src/main/AndroidManifest.xml
```

as permissões descritas em `ANDROID_MANIFEST_PERMISSIONS.txt`.

Para um projeto Firebase Android de produção, registre o applicationId no Firebase
e conclua a configuração nativa conforme o console do Firebase.

## iOS

Veja `IOS_INFO_PLIST_KEYS.txt`. No Xcode habilite:

- Push Notifications
- Background Modes > Remote notifications

## Sincronização com o backend

O aplicativo vem com:

```text
USE_BACKEND=false
```

Assim toda a demonstração funciona localmente.

Quando o login JWT e o endpoint de FCM do time estiverem disponíveis, rode com:

```powershell
flutter run -d chrome `
  --dart-define=USE_BACKEND=true `
  --dart-define=API_BASE_URL=http://127.0.0.1:5000 `
  ...credenciais Firebase...
```

Nesse modo, o token do Firebase é enviado pelo `FcmTokenApi` usando o Bearer token
guardado na sessão.
