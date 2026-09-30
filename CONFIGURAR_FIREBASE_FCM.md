# Firebase Cloud Messaging (FCM) — configuração final

O código desta versão já implementa o fluxo solicitado ao time Flutter:

1. `firebase_messaging` e `firebase_core` no `pubspec.yaml`.
2. Pedido de permissão ao usuário.
3. Captura do token com `FirebaseMessaging.instance.getToken()`.
4. Atualização automática quando o token muda (`onTokenRefresh`).
5. Registro opcional após o login:
   - `POST /api/usuarios/fcm-token`
   - JSON: `{"token":"TOKEN_DO_DISPOSITIVO","dispositivo_id":"ID_DA_INSTALACAO"}`
6. Remoção no logout:
   - `DELETE /api/usuarios/fcm-token?dispositivo_id=ID_DA_INSTALACAO`
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

O login JWT e os endpoints de registro/remoção e teste FCM estão implementados. Para usá-los, rode com:

```powershell
flutter run -d chrome `
  --dart-define=USE_BACKEND=true `
  --dart-define=API_BASE_URL=http://127.0.0.1:5000 `
  ...credenciais Firebase...
```

Nesse modo, o token do Firebase é enviado pelo `FcmTokenApi` usando o Bearer token
guardado na sessão.

## Preparação automática da configuração Web

O script `CONFIGURAR_FIREBASE_WEB.ps1` agora recebe também `-WebVapidKey` e gera tanto o service worker quanto `firebase-web.local.json`, evitando configurar projetos diferentes no Flutter e no worker. Execute no PowerShell usando os valores públicos do Firebase Console:

```powershell
.\CONFIGURAR_FIREBASE_WEB.ps1 -ApiKey 'VALOR_PUBLICO' -AuthDomain 'DOMINIO' -ProjectId 'PROJETO' -StorageBucket 'BUCKET' -MessagingSenderId 'REMETENTE' -AppId 'APP_ID' -WebVapidKey 'VAPID_PUBLICA'
flutter run -d chrome --web-port=8080 --dart-define-from-file=firebase-web.local.json
```

O arquivo gerado inclui `USE_BACKEND=true` e o endereço local da API. Configure `-ApiBaseUrl` para usar outro endereço. Reinicie o Flutter após mudar os valores. O JSON é configuração pública do cliente, nunca uma chave de conta de serviço; não coloque chaves privadas nesses arquivos. O JSON local e o worker gerado ficam ignorados pelo Git.

Para testar: faça login, abra Perfil → Notificações, ative a permissão e use “Testar recebimento de notificação”. O retorno da API conta envios aceitos pelo FCM, não confirma entrega. Confira o recebimento com a aba em foco e em segundo plano. O exemplo do worker evita exibir duas vezes mensagens que já contêm `notification`, seguindo o [contrato do Firebase](https://firebase.google.com/docs/cloud-messaging/web/receive-messages).

Validação real ainda pendente. Registro, rotação, remoção e envio simulado estão cobertos por testes. Nenhum envio automático para eventos de reserva/chat está ativado.
