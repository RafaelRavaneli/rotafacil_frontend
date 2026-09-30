# RotaFácil — Frontend

Aplicativo Flutter para descoberta, planejamento e agendamento de trilhas. O frontend atende turistas, guias e agências e pode funcionar com dados locais de demonstração ou conectado à API Flask do RotaFácil.

## Fluxo de acesso

- **Fazer login:** solicita somente e-mail e senha. O backend informa o tipo da conta e o aplicativo abre a home correspondente.
- **Criar conta:** solicita primeiro a escolha entre turista, guia e agência.
- **Documentos:** CPF e CNPJ são validados somente no cadastro do perfil correspondente, nunca no login.

## Tecnologias

- Flutter e Dart
- `http` para a API REST
- `shared_preferences` para sessão e dados locais
- `firebase_core` e `firebase_messaging` para notificações
- `geolocator` para localização
- `image_picker` para seleção de imagens

## Estrutura principal

```text
lib/
├── config/       # Configuração do aplicativo e Firebase
├── data/         # Dados de demonstração
├── models/       # Modelos do domínio
├── pages/        # Telas por área e perfil
├── services/     # API, autenticação, sessão e notificações
├── state/        # Estado global
├── theme/        # Tema visual
├── utils/        # Validadores e tratamento de erros
└── widgets/      # Componentes reutilizáveis
```

## Modos de execução

### Modo local

Utiliza dados fictícios e persistência local. Não exige que o backend esteja ativo.

```powershell
flutter pub get
flutter run -d chrome
```

Contas de demonstração:

| Perfil | E-mail | Senha |
|---|---|---|
| Turista | `thiago@email.com` | `123456` |
| Guia | `guia@email.com` | `123456` |
| Agência | `contato@aventuraprime.com` | `123456` |

### Modo conectado

Utiliza autenticação JWT, persistência e serviços da API real. Inicie antes o repositório `rotafacil_backend`.

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Variáveis aceitas por `--dart-define`:

| Variável | Padrão | Finalidade |
|---|---|---|
| `USE_BACKEND` | `false` | Habilita a integração com a API |
| `API_BASE_URL` | `http://127.0.0.1:5000` | Endereço base do backend |
| `FIREBASE_WEB_VAPID_KEY` | vazio | Chave pública necessária ao push web |

Para configurar Firebase Web e VAPID, siga `CONFIGURAR_FIREBASE_FCM.md` ou execute `CONFIGURAR_FIREBASE_WEB.ps1`. Os arquivos locais gerados são ignorados pelo Git.

## Recursos conectados à API

- cadastro e login por e-mail e senha;
- recuperação de senha;
- sessão por JWT;
- consulta, criação, edição e desativação de trilhas;
- agendamento e cancelamento;
- favoritos;
- atualização de perfil e upload de imagens;
- catálogo de guias e convites entre agência e guia;
- conversas entre turista e guia;
- atendimento de suporte;
- registro, remoção e teste do dispositivo para push;
- indicadores de agendamentos fornecidos pela API.

## Verificações

```powershell
flutter analyze
flutter test
flutter test --dart-define=USE_BACKEND=true
flutter build web --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Os testes automatizados não substituem a validação com Firebase, e-mail, ImgBB e contas reais de homologação.

## Limitações conhecidas

- conversas são atualizadas manualmente e mantêm somente as mensagens mais recentes;
- o suporte pode ser respondido por administrador pela API, mas ainda não possui painel administrativo no aplicativo;
- convites não possuem reenvio ou revogação;
- push possui registro e envio de teste, mas o recebimento real precisa ser homologado no navegador;
- avaliações, planejamento completo da trilha, contato de emergência e verificação administrativa ainda não formam fluxos completos na interface;
- não existe publicação pública de produção confirmada.

## Repositórios relacionados

- Backend: https://github.com/RafaelRavaneli/rotafacil_backend
- Documentação: https://github.com/RafaelRavaneli/rotafacil_docs
