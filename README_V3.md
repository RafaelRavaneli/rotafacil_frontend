# RotaFácil V3 — Front-end completo

Esta versão foi reestruturada para que os principais fluxos funcionem mesmo
sem o backend.

## Autenticação local

Perfis demonstrativos:

### Turista
- E-mail: `thiago@email.com`
- Senha: `123456`

### Guia
- E-mail: `guia@email.com`
- Senha: `123456`

### Agência
- E-mail: `contato@aventuraprime.com`
- Senha: `123456`

Cadastro, login, redefinição de senha e alteração de senha funcionam localmente.
Os dados são persistidos com `shared_preferences`.

## Funcionalidades

### Todos os perfis
- editar perfil
- dados pessoais
- notificações
- central de notificações
- preferências de privacidade
- alterar senha
- ajuda e suporte
- logout
- dados persistentes

### Turista
- home
- favoritos
- detalhes de trilha
- busca por cidade
- busca por estado
- filtro por dificuldade
- filtro por período
- GPS e busca por raio de 5 a 100 km
- distância real até a trilha
- agendamento
- cancelamento de agendamento
- histórico
- mensagens

### Guia
- dashboard dinâmico
- criar trilha
- editar trilha
- excluir trilha
- escolher foto da galeria
- usar GPS na trilha
- preço, data, modalidade e dificuldade
- agendamentos
- mensagens
- perfil completo

### Agência
- dashboard dinâmico
- convidar guia
- alterar status do guia
- remover guia
- criar/editar/excluir trilhas
- escolher guia responsável
- escolher foto
- GPS
- agendamentos
- perfil completo

## FCM

O fluxo de Firebase Messaging solicitado está implementado.
Leia `CONFIGURAR_FIREBASE_FCM.md`.

O único ponto que depende de dados externos é o envio/recebimento REAL pelo Firebase:
é necessário colocar as credenciais do projeto Firebase do time.

## Como abrir

Se acabou de extrair este ZIP e ainda não existem `android`, `web`, `windows` etc.:

```powershell
flutter create .
```

Depois:

```powershell
flutter pub get
flutter analyze
flutter run -d chrome
```

O arquivo `test/widget_test.dart` já está preparado para o `RotaFacilApp`.

## Modo backend opcional

A versão padrão é local.

Para ativar login JWT/API:

```text
--dart-define=USE_BACKEND=true
--dart-define=API_BASE_URL=http://127.0.0.1:5000
```

O login passa a usar `/api/auth/login`, guarda o JWT e abre a tela de acordo
com o campo `tipo` retornado pela API.
