# RotaFácil — Frontend

Aplicativo Flutter para descoberta e agendamento de trilhas. O frontend atende turistas, guias e agências e pode funcionar com dados locais de demonstração ou conectado à API Flask do RotaFácil.

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
- `flutter_map` e `latlong2` para o mapa dos resultados filtrados

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

Utiliza autenticação JWT, persistência e serviços da API real. Para testar com a API publicada, não é necessário instalar o backend nem configurar um .env no frontend. Use contas reais de homologação; contas demonstrativas só existem no modo local.

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=https://rotafacil-backend-woad.vercel.app
```

Variáveis aceitas por `--dart-define`:

| Variável | Padrão | Finalidade |
|---|---|---|
| `USE_BACKEND` | `false` | Habilita a integração com a API |
| `API_BASE_URL` | `http://127.0.0.1:5000` | Endereço base do backend |
| `FIREBASE_WEB_VAPID_KEY` | vazio | Chave pública necessária ao push web |

Para configurar Firebase Web e VAPID, siga [docs/FIREBASE.md](docs/FIREBASE.md) ou execute `scripts/CONFIGURAR_FIREBASE_WEB.ps1`. Os arquivos locais gerados são ignorados pelo Git.

## Recursos conectados à API

- cadastro e login por e-mail e senha;
- interface de recuperação de senha (entrega de e-mail adiada);
- sessão por JWT;
- alteração de senha autenticada, com conferência da senha atual;
- consulta, criação, edição e desativação de trilhas;
- agendamento e cancelamento;
- favoritos;
- atualização de perfil e upload de imagens;
- exclusão segura da conta, bloqueada enquanto houver reservas ativas;
- alteração do tipo da conta com validação de CPF/CNPJ e novo login;
- catálogo de guias e convites entre agência e guia;
- registro, remoção e teste do dispositivo para push;
- indicadores de agendamentos fornecidos pela API.
- documentos profissionais privados, acompanhamento da análise e painel administrativo.

## Guias e convites

No modo conectado, a agência consulta o catálogo de guias e envia convites usando o identificador do guia. O catálogo não representa a equipe da agência: somente convites aceitos formam vínculos. O guia consulta os convites recebidos pela opção "Convites de agências" no Perfil.

Envio, aceite, recusa, revogação, reenvio e desligamento possuem confirmação. As telas mostram carregamento, ausência de resultados, erro e tentativa novamente. Enquanto uma ação está em andamento, novas ações ficam bloqueadas. O desligamento é bloqueado enquanto houver reservas ativas no vínculo.

No modo local, a agência pode adicionar e gerenciar registros demonstrativos neste dispositivo. Essa operação não envia um convite real e não simula uma resposta de outro usuário.

Os testes de convites utilizam respostas HTTP simuladas. Ainda é necessário validar o fluxo completo com contas de agência e guia no backend real.

## Verificações

```powershell
flutter analyze
flutter test
flutter test --dart-define=USE_BACKEND=true
flutter build web --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=https://rotafacil-backend-woad.vercel.app
```

Os testes automatizados não substituem a validação com Firebase, e-mail, ImgBB e contas reais de homologação.

## Limitações conhecidas

- a ajuda é orientativa; o código de chat e atendimento por conversas foi removido;
- push possui registro e envio de teste, mas o recebimento real precisa ser homologado no navegador;
- armazenamento privado de documentos exige `FIREBASE_STORAGE_BUCKET` e permissão da conta de serviço no Firebase Storage;
- backend publicado no Vercel; frontend público e homologação completa ainda pendentes. Não confundir build/testes simulados com aprovação dos fluxos reais.

## Repositórios relacionados

- Backend: https://github.com/RafaelRavaneli/rotafacil_backend
- Documentação: https://github.com/RafaelRavaneli/rotafacil_docs

## Documentação e ferramentas

- [Integração e contratos](docs/INTEGRACAO.md): modos de execução, endpoints e limites.
- [Firebase e plataformas](docs/FIREBASE.md): configuração web, permissões Android/iOS e testes de push.
- [Histórico](docs/HISTORICO.md): registros antigos V2–V6, sem validade como instrução atual.
- `scripts/CONFIGURAR_FIREBASE_WEB.ps1`: gera a configuração pública local e o service worker.
- `scripts/SETUP_PROJETO.ps1`: preparação opcional de plataformas; não executar para testar o web já existente. Execute a partir da raiz do frontend.

Os arquivos de referência PDF e imagem em docs foram preservados. build, .dart_tool e configurações locais são gerados/ignorados e não integram o código versionado. pubspec.lock, configuração web e arquivos de testes são necessários e permanecem separados por responsabilidade.
