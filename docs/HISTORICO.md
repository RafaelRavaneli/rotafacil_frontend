# Histórico do frontend

Consolidação dos registros V2–V6 em 14/10/2026. Este documento preserva o histórico, não descreve os recursos atuais. Instruções antigas sobre login com documento, chat, suporte por mensagens e geração de plataformas foram substituídas. Consulte o README e docs/INTEGRACAO.md para executar e testar a versão atual. Validações estáticas antigas não equivalem a testes Flutter.

---

## Registro original: README_FRONTEND_V2.md

# RotaFácil Front-end V2 — fluxo completo sem backend

Esta versão foi reestruturada para que todas as principais telas e interações funcionem no próprio front-end.

## Incluído

### Todos os perfis
- editar perfil
- dados pessoais
- notificações
- privacidade e segurança
- ajuda e suporte
- sair da conta

### Turista
- home
- busca de trilhas
- filtro por nome/cidade/estado
- filtro por dificuldade
- filtro por distância do percurso
- detalhes da trilha
- agendamento
- cancelamento de agendamento
- tela de agendamentos
- perfil completo

### Guia
- dashboard
- lista de trilhas
- adicionar trilha
- adicionar foto da trilha com `image_picker`
- excluir trilha
- tela de agendamentos
- perfil completo

### Agência
- dashboard
- lista de guias
- convidar guia
- ativar/remover guia
- lista de trilhas
- adicionar trilha
- selecionar guia responsável
- adicionar foto
- agendamentos
- perfil completo

## Importante

Tudo funciona localmente usando `AppStore`, portanto esta versão não depende do backend para demonstração.

Os dados ficam em memória durante a execução. Ao fechar totalmente o aplicativo, os dados adicionados durante o teste são reiniciados.

## Para rodar

```bash
flutter pub get
flutter analyze
flutter run -d chrome
```

---

## Registro original: README_V3.md

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

---

## Registro original: README_V4.md

# RotaFácil V4 — correções e fluxos completos

Esta versão inclui as correções solicitadas depois do teste da V3.

## Corrigido
- Aba **Trilhas** de Guia/Agência reescrita com `Column + ListView`, evitando a tela branca observada.
- Correção do `AuthorizationStatus.deniedPermanently` do Firebase Messaging.

## Perfil
- Foto de perfil pela galeria.
- Pré-visualização da foto.
- Remover/trocar foto.
- Foto persistida localmente.
- Foto aparece no Perfil e nos painéis de Guia/Agência.
- Nome, e-mail, telefone, cidade e estado editáveis.
- CPF editável/obrigatório para Guia.
- CNPJ editável/obrigatório para Agência.

## Autenticação
### Turista
- e-mail + senha.

### Guia
- e-mail + CPF + senha.
- CPF é obrigatório e passa por validação dos dígitos verificadores.

Conta de demonstração:
- e-mail: `guia@email.com`
- CPF: `529.982.247-25`
- senha: `123456`

### Agência
- e-mail + CNPJ + senha.
- CNPJ é obrigatório e passa por validação dos dígitos verificadores.

Conta de demonstração:
- e-mail: `contato@aventuraprime.com`
- CNPJ: `11.222.333/0001-81`
- senha: `123456`

## Mensagens Turista ↔ Guia
A conversa agora é compartilhada:
- Turista envia para Guia.
- Guia envia para Turista.
- As mensagens ficam persistidas.
- Para testar os dois lados, envie como Turista, faça logout e entre como Guia.

## Ajuda e suporte
- Usuário envia mensagem ao suporte.
- Histórico fica salvo.
- Existe um botão de **atendente** no canto superior para **Responder como suporte** em modo de demonstração.
- A resposta aparece na mesma conversa.
- A resposta do suporte também gera notificação.

## Para rodar
Se necessário:

```powershell
flutter create .
flutter pub get
flutter analyze
flutter run -d chrome
```

Como esta V4 altera o modelo local de autenticação, as contas demonstrativas usam os dados listados acima.

---

## Registro original: README_V5.md

A introdução e as instruções repetiam integralmente README_V4.md, preservado acima. Abaixo estão apenas os acréscimos da V5.

## V5 — Guias clicáveis
- Os cards em **Guias disponíveis** agora são clicáveis.
- Cursor muda para mãozinha no Chrome/Web.
- Tela pública do guia com foto, verificação, nota, avaliações, especialidades, experiência, trilhas concluídas e quilômetros guiados.
- Botão **Conversar com o guia** abre uma conversa vinculada ao guia selecionado.
- As conversas com guias diferentes ficam separadas localmente.
- As trilhas daquele guia aparecem dentro do perfil e são clicáveis.
- Em **Detalhes da trilha**, o bloco **Guia responsável** também abre o perfil do guia.

---

## Registro original: CORRECAO_CONGELAMENTO_V6.md

# Correção de congelamento — V6

O principal ajuste desta versão foi a arquitetura das abas.

## Problema encontrado

As shells de Turista, Guia e Agência usavam:

```dart
IndexedStack(
  index: index,
  children: tabs,
)
```

O `IndexedStack` mantém todas as abas montadas ao mesmo tempo.
Isso significa que, ao entrar como Guia ou Agência, o Flutter construía
simultaneamente:

- dashboard;
- lista de trilhas;
- agenda;
- mensagens/guias;
- perfil;
- imagens locais e remotas;
- vários `AnimatedBuilder`.

No Chrome isso pode deixar a interface muito pesada, principalmente
quando já existem fotos salvas como `data:image;base64`.

## Correção

Agora cada Shell usa um `switch` e monta apenas a aba selecionada.

Exemplo:

```dart
Widget _currentPage() {
  switch (index) {
    case 0:
      return const GuideDashboardTab();
    case 1:
      return const TrailsManagementScreen(isAgency: false);
    ...
  }
}
```

Também foi removido o `IndexedStack`.

## Otimização de imagens

`ProfileAvatar` e `NetworkImageBox` agora guardam os bytes decodificados
no `State` do widget. O Base64 não é convertido de novo em todo rebuild.

As novas fotos também são reduzidas antes de serem armazenadas:

- Perfil: largura máxima 640, qualidade 60;
- Trilha: largura máxima 900, qualidade 60.

Isso reduz o custo do `shared_preferences` no navegador.

## Teste

Depois de extrair:

```powershell
flutter create .
flutter pub get
flutter analyze
flutter run -d chrome
```

Teste:

1. Guia > Painel > Trilhas > Agenda > Mensagens > Perfil.
2. Agência > Painel > Guias > Trilhas > Agendamentos > Perfil.
3. Volte várias vezes entre as abas.

Nenhuma aba escondida permanece sendo renderizada.

---

## Registro original: MAPA_DE_FUNCIONALIDADES.md

# Checklist funcional — RotaFácil V3

## Entrada
- [x] Boas-vindas
- [x] Escolha Turista / Guia / Agência
- [x] Login com senha
- [x] Cadastro
- [x] Esqueci minha senha
- [x] Logout

## Turista
- [x] Home
- [x] Lista de trilhas
- [x] Abrir detalhes
- [x] Favoritar / desfavoritar
- [x] Tela de favoritos
- [x] Busca por cidade
- [x] Busca por estado
- [x] Filtro por dificuldade
- [x] Filtro por período
- [x] Permissão de GPS
- [x] Busca por proximidade
- [x] Raio 5–100 km
- [x] Ordenação pela distância ao usuário
- [x] Agendar trilha
- [x] Ver agendamentos
- [x] Cancelar agendamento
- [x] Mensagens

## Guia
- [x] Dashboard
- [x] Indicadores
- [x] Ver agenda
- [x] Criar trilha
- [x] Editar trilha
- [x] Excluir trilha
- [x] Selecionar foto
- [x] Definir localização por GPS
- [x] Modalidade
- [x] Dificuldade
- [x] Distância
- [x] Data
- [x] Preço
- [x] Mensagens

## Agência
- [x] Dashboard
- [x] Indicadores
- [x] Convidar guia
- [x] Ativar guia
- [x] Marcar guia pendente
- [x] Remover guia
- [x] Criar trilha
- [x] Editar trilha
- [x] Excluir trilha
- [x] Selecionar guia responsável
- [x] Foto
- [x] GPS
- [x] Agendamentos

## Perfil — todos
- [x] Editar perfil
- [x] Dados pessoais
- [x] Alterar e-mail de login local
- [x] Notificações
- [x] Central de notificações
- [x] Notificação local de teste
- [x] Privacidade
- [x] Alterar senha
- [x] Sessão atual
- [x] Ajuda e suporte

## Firebase Cloud Messaging
- [x] firebase_core
- [x] firebase_messaging
- [x] pedir permissão
- [x] getToken()
- [x] onTokenRefresh
- [x] POST /api/usuarios/fcm-token quando backend JWT estiver ativo
- [x] DELETE /api/usuarios/fcm-token no logout
- [x] onMessage (foreground)
- [x] onMessageOpenedApp
- [x] getInitialMessage
- [x] handler de background Android/iOS
- [x] service worker Web fornecido como template

## Persistência
- [x] Perfil
- [x] Guias
- [x] Trilhas
- [x] Agendamentos
- [x] Favoritos
- [x] Mensagens
- [x] Configurações
- [x] Notificações

Os itens de Firebase que dependem de comunicação real com o FCM exigem as
credenciais do projeto Firebase do time. O código não pode inventar essas credenciais.

---

## Registro original: VALIDACAO_ESTATICA.txt

RotaFácil V3 — validação estática feita na geração

Arquivos Dart verificados: 53
Imports relativos inexistentes: 0
Arquivos com delimitadores desbalanceados: 0
Callbacks vazios onPressed/onTap encontrados: 0
Padrões de underscores que causavam os avisos anteriores: 0

IMPORTANTE:
O ambiente que gerou o ZIP não possui o executável Flutter/Dart.
Por isso esta checagem NÃO substitui `flutter analyze` no seu computador.

Depois de extrair:
1. flutter create .
2. flutter pub get
3. flutter analyze
4. flutter run -d chrome

Imports ausentes:
Nenhum

Delimitadores:
Nenhum problema detectado

---

## Registro original: VALIDACAO_ESTATICA_V4.txt

RotaFácil V4 — checagem estrutural da geração

Arquivos Dart: 56
Imports relativos inexistentes: 0
Arquivos com delimitadores desbalanceados: 0

Esta checagem não substitui `flutter analyze` no seu computador, pois
o ambiente de geração não possui o executável Flutter.

Imports ausentes:
Nenhum

Delimitadores:
Nenhum problema detectado

---

## Registro original: VALIDACAO_ESTATICA_V5.txt

Arquivos Dart: 57
Imports ausentes: 0
Delimitadores desbalanceados: 0

---

## Registro original: VALIDACAO_ESTATICA_V6.txt

RotaFácil V6 — checagem estrutural

Arquivos Dart: 57
Imports relativos inexistentes: 0
Arquivos com delimitadores desbalanceados: 0

Imports ausentes:
Nenhum

Delimitadores:
Nenhum problema detectado

OBS:
A validação definitiva deve ser feita com `flutter analyze`
no computador do projeto.

---

## Registro original: ARQUIVOS_INCLUIDOS_V3.txt

ANDROID_MANIFEST_PERMISSIONS.txt
ARQUIVOS_INCLUIDOS.txt
CONFIGURAR_FIREBASE_FCM.md
CONFIGURAR_FIREBASE_WEB.ps1
IOS_INFO_PLIST_KEYS.txt
MAPA_DE_FUNCIONALIDADES.md
README.md
README_V3.md
SETUP_PROJETO.ps1
VALIDACAO_ESTATICA.txt
analysis_options.yaml
docs/Documento_de_Integracao_RotaFacil.pdf
docs/Requisitos_Firebase_Messaging.jpeg
lib/app.dart
lib/config/app_config.dart
lib/config/firebase_runtime_options.dart
lib/data/demo_data.dart
lib/main.dart
lib/models/app_notification.dart
lib/models/app_user.dart
lib/models/chat_message.dart
lib/models/guide.dart
lib/models/local_booking.dart
lib/models/local_guide.dart
lib/models/trail.dart
lib/models/user_role.dart
lib/pages/agency/agency_dashboard_tab.dart
lib/pages/agency/agency_shell.dart
lib/pages/agency/guides_screen.dart
lib/pages/auth/forgot_password_screen.dart
lib/pages/auth/login_screen.dart
lib/pages/auth/profile_choice_screen.dart
lib/pages/auth/register_screen.dart
lib/pages/auth/welcome_screen.dart
lib/pages/common/bookings_screen.dart
lib/pages/common/favorites_screen.dart
lib/pages/common/messages_screen.dart
lib/pages/common/notification_center_screen.dart
lib/pages/common/profile_tab.dart
lib/pages/common/settings/help_support_screen.dart
lib/pages/common/settings/notifications_screen.dart
lib/pages/common/settings/personal_data_screen.dart
lib/pages/common/settings/privacy_security_screen.dart
lib/pages/common/trails_management_screen.dart
lib/pages/guide/guide_dashboard_tab.dart
lib/pages/guide/guide_shell.dart
lib/pages/management/trail_form_screen.dart
lib/pages/tourist/tourist_home_tab.dart
lib/pages/tourist/tourist_shell.dart
lib/pages/tourist/trail_details_screen.dart
lib/pages/tourist/trail_search_screen.dart
lib/services/api_client.dart
lib/services/auth_gateway.dart
lib/services/fcm_token_api.dart
lib/services/local_auth_service.dart
lib/services/notification_service.dart
lib/services/session_service.dart
lib/state/app_store.dart
lib/theme/app_colors.dart
lib/theme/app_theme.dart
lib/widgets/app_logo.dart
lib/widgets/market_search.dart
lib/widgets/network_image_box.dart
lib/widgets/role_card.dart
lib/widgets/status_pill.dart
pubspec.yaml
test/widget_test.dart
web/firebase-messaging-sw.js.example

---

## Registro original: ARQUIVOS_INCLUIDOS_V4.txt

ANDROID_MANIFEST_PERMISSIONS.txt
ARQUIVOS_INCLUIDOS_V3.txt
CONFIGURAR_FIREBASE_FCM.md
CONFIGURAR_FIREBASE_WEB.ps1
IOS_INFO_PLIST_KEYS.txt
MAPA_DE_FUNCIONALIDADES.md
README.md
README_FRONTEND_V2.md
README_V3.md
README_V4.md
SETUP_PROJETO.ps1
VALIDACAO_ESTATICA.txt
VALIDACAO_ESTATICA_V4.txt
analysis_options.yaml
docs/Documento_de_Integracao_RotaFacil.pdf
docs/Requisitos_Firebase_Messaging.jpeg
lib/app.dart
lib/config/app_config.dart
lib/config/firebase_runtime_options.dart
lib/data/demo_data.dart
lib/main.dart
lib/models/app_notification.dart
lib/models/app_user.dart
lib/models/chat_message.dart
lib/models/guide.dart
lib/models/local_booking.dart
lib/models/local_guide.dart
lib/models/support_message.dart
lib/models/trail.dart
lib/models/user_role.dart
lib/pages/agency/agency_dashboard_tab.dart
lib/pages/agency/agency_shell.dart
lib/pages/agency/guides_screen.dart
lib/pages/auth/forgot_password_screen.dart
lib/pages/auth/login_screen.dart
lib/pages/auth/profile_choice_screen.dart
lib/pages/auth/register_screen.dart
lib/pages/auth/welcome_screen.dart
lib/pages/common/bookings_screen.dart
lib/pages/common/favorites_screen.dart
lib/pages/common/messages_screen.dart
lib/pages/common/notification_center_screen.dart
lib/pages/common/profile_tab.dart
lib/pages/common/settings/help_support_screen.dart
lib/pages/common/settings/notifications_screen.dart
lib/pages/common/settings/personal_data_screen.dart
lib/pages/common/settings/privacy_security_screen.dart
lib/pages/common/trails_management_screen.dart
lib/pages/guide/guide_dashboard_tab.dart
lib/pages/guide/guide_shell.dart
lib/pages/management/trail_form_screen.dart
lib/pages/tourist/tourist_home_tab.dart
lib/pages/tourist/tourist_shell.dart
lib/pages/tourist/trail_details_screen.dart
lib/pages/tourist/trail_search_screen.dart
lib/services/api_client.dart
lib/services/auth_gateway.dart
lib/services/fcm_token_api.dart
lib/services/local_auth_service.dart
lib/services/notification_service.dart
lib/services/session_service.dart
lib/state/app_store.dart
lib/theme/app_colors.dart
lib/theme/app_theme.dart
lib/utils/document_validator.dart
lib/widgets/app_logo.dart
lib/widgets/market_search.dart
lib/widgets/network_image_box.dart
lib/widgets/profile_avatar.dart
lib/widgets/role_card.dart
lib/widgets/status_pill.dart
pubspec.yaml
test/widget_test.dart
web/firebase-messaging-sw.js.example
