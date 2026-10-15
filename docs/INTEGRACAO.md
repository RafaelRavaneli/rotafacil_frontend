# RotaFácil — execução local e integração

Revisão consolidada em 14/10/2026 nos repositórios `D:/projetos/rotafacil_frontend`, `rotafacil_backend` e `rotafacil_docs`. A pasta `rotafacil-app` foi ignorada.

## Estrutura e tecnologias

| Pasta | Conteúdo |
|---|---|
| Frontend `lib/pages` | Telas de autenticação, turista, guia, agência, perfil e administração de trilhas |
| Frontend `lib/state/app_store.dart` | Estado compartilhado, modo demonstrativo e operações remotas |
| Frontend `lib/services` | HTTP, autenticação, sessão, notificações e adaptador de contratos da API |
| Frontend `lib/models`, `widgets`, `theme`, `utils` | Modelos, componentes, estilos e validações |
| Frontend `web` | Entrada web Flutter e exemplo de service worker FCM |
| Backend `app.py`, `routes`, `services`, `models` | Aplicação Flask, rotas HTTP, regras e inicialização Firestore |
| Documentação | Planejamento, POPs, sprints, integração e evidências do projeto |

Frontend: Flutter/Dart (restrição Dart `^3.11.4`), HTTP, SharedPreferences, Firebase Core/Messaging, ImagePicker e Geolocator. Backend: Python 3.13, Flask, Flask-CORS, Firebase Admin/Firestore, JWT e ImgBB. As dependências permanecem declaradas em `pubspec.yaml` e `requirements.txt`.

## Executar

Para usar a API publicada, não é necessário instalar o backend ou configurar .env no frontend:

```powershell
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=https://rotafacil-backend-woad.vercel.app
```

Para executar também o backend local:

Em um terminal:

```powershell
cd D:/projetos/rotafacil_backend
.\venv\Scripts\python.exe app.py
```

Em outro:

```powershell
cd D:/projetos/rotafacil_frontend
flutter run -d chrome --web-port=8080 --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Para demonstração local, omita `USE_BACKEND=true`. O padrão permanece demonstrativo. Os arquivos de entrada web foram gerados para permitir executar a aplicação sem recriar o projeto.

O backend precisa de `.env` e `firebase-key.json`, que já existiam na máquina. Seus valores não foram alterados nem incluídos nos testes. O `.env.example` documenta JWT (`KEY`) e ImgBB. O serviço de e-mail exige configuração SMTP no backend; essa configuração está adiada. FCM web utiliza as opções em `firebase_runtime_options.dart`, a chave VAPID e o service worker indicado em `FIREBASE.md`.

CORS aceita, por padrão, origens HTTP locais `localhost` e `127.0.0.1` com porta. Para outro ambiente, configure `CORS_ORIGINS` com origens exatas separadas por vírgula. No Android emulador, o endereço do computador normalmente deve ser configurado como `http://10.0.2.2:5000`; plataformas móveis ainda precisam ser geradas/configuradas e não foram validadas nesta etapa.

## Fluxos conectados

| Operação | Contrato utilizado |
|---|---|
| Cadastro | `POST /api/usuarios/`, com `documento` para CPF/CNPJ |
| Login | `POST /api/auth/login`, seguido de carga do perfil e dados; JWT inclui ID |
| Perfil | `GET` e `PUT /api/usuarios/<id>`; campos `nome`, `telefone`, `cidade`, `estado`, `documento`, `foto_url` |
| Fotos | `POST /api/uploads/imagem`, multipart com campo `image`; resposta `url` |
| Trilhas | `GET`/`POST /api/trilhas/`, `PUT`/`DELETE /api/trilhas/<id>` |
| Favoritos | `GET`/`POST /api/favoritos/`, `DELETE /api/favoritos/<id_trilha>` |
| Agendamentos | `POST /api/agendamentos/`, listagens por usuário/guia e `PUT /api/agendamentos/<id>/cancelar` |
| Recuperação de senha | `POST /api/auth/senha/solicitar` e `POST /api/auth/senha/redefinir` com `token` e `nova_senha` |

Datas de formulário são convertidas de DD/MM/AAAA para AAAA-MM-DD. O preço é mapeado para `preco`. `agendado` aparece como Confirmado; `em_andamento` e `concluido` têm rótulos próprios. A desativação de trilhas preserva os documentos e agendamentos existentes e impede novas reservas. Trilhas antigas que usam e-mail como responsável continuam sendo consideradas na agenda do guia.

O carregamento inicial não mistura listas demonstrativas com dados do servidor. Falhas na restauração da sessão oferecem nova tentativa ou retorno ao login. A alteração de e-mail não invalida a identificação do usuário pelo ID. Requisições têm tempo limite e as telas conectadas exibem falhas sem ficarem presas no estado de salvamento.

## Verificação

```powershell
# Frontend
flutter analyze
flutter test
flutter test --dart-define=USE_BACKEND=true
flutter build web --dart-define=USE_BACKEND=true --dart-define=API_BASE_URL=http://127.0.0.1:5000

# Backend
.\venv\Scripts\python.exe -m unittest discover -s tests -v
```

Os testes usam clientes HTTP e banco simulados. Cobrem contratos, UTF-8, autenticação, autorização, CORS, cadastro, mapeamento de dados, desativação de trilhas e indisponibilidade da API. Não criam registros no Firebase nem enviam e-mails ou imagens para serviços externos.

## Próximas etapas e limites

- Validar com contas de teste reais o percurso cadastro → login → trilha → favorito → reserva → cancelamento, além de upload ImgBB. Recuperação por e-mail está adiada até configurar e validar SMTP. Essas integrações externas não foram comprovadas pelos testes simulados.
- Chat e suporte por mensagens foram removidos. Catálogo e convites de guias permanecem disponíveis; o fluxo entre duas contas reais ainda precisa ser homologado.
- O endpoint `/api/usuarios/fcm-token` registra e remove dispositivos, com rotação de token. O teste de envio é restrito à própria conta. Firebase/VAPID/service worker e recebimento real continuam pendentes; não há envio automático por eventos de reservas nesta etapa.
- Avaliações, check-in/check-out, clima, rotas de navegação e campos de acessibilidade já possuem recursos no backend, mas precisam de uma próxima etapa de interface.
- A rota de dashboard calcula contagens por status e valores declarados das reservas não canceladas, incluindo referências legadas por e-mail. Não representa conciliação financeira. Os painéis do frontend continuam usando os dados carregados.
- O catálogo remoto permite convidar guias. Após aceite pelo guia, ele aparece no seletor de responsável por ID. Novas trilhas podem usar a própria agência como responsável. Recusa é definitiva nesta versão: reenvio e revogação de convites ainda não têm interface.
- A exclusão de trilha é desativação lógica. Não há migração destrutiva nem limpeza de dados legados.

Esta organização não publica nem cria commits automaticamente. Os registros antigos do frontend foram consolidados em HISTORICO.md. A documentação de rotafacil_docs foi preservada.

Contratos de guias e convites: `CONTRATOS_COMUNIDADE.md` no repositório do backend. Swagger: https://rotafacil-backend-woad.vercel.app/docs.


## Identificação da agenda de guia e agência

O frontend consulta a agenda por ID da sessão autenticada, sem repetir a chamada usando o e-mail. No backend atualizado, a mesma consulta reúne registros pelo ID e pelo e-mail atual do responsável, preservando agendamentos antigos sem duplicar resultados. A regra de autorização da rota permanece em vigor; falhas de acesso à agenda por ID continuam sendo exibidas. Essa compatibilidade depende de executar/publicar também a atualização de services/agendamentos.py no backend.


## Atualização de reservas e desativação de trilhas

Agenda e painéis de guia/agência consultam a API ao abrir e quando o aplicativo volta ao primeiro plano. O botão Atualizar reservas e o gesto de puxar a lista repetem a consulta. Não há assinatura em tempo real; reservas feitas em outro dispositivo aparecem após essa atualização. Falhas mantêm os dados anteriores e mostram aviso, sem indicar atualização concluída.

Trilhas com reservas pendentes, confirmadas ou em andamento não podem ser desativadas. O backend retorna HTTP 409 tanto na exclusão lógica quanto na edição com ativo=false. É necessário cancelar ou concluir as reservas antes. Reservas canceladas e concluídas permanecem no histórico; nenhuma reserva é apagada em cascata. O modo demonstrativo segue a mesma regra. A validação do servidor precisa estar publicada para valer contra todos os clientes.
