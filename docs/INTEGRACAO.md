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
| Excluir conta | `DELETE /api/usuarios/<id>`; bloqueia com HTTP 409 enquanto houver reservas ativas |
| Alterar tipo | `PUT /api/usuarios/<id>/tipo`; exige CPF para guia, CNPJ para agência e novo login |
| Fotos | `POST /api/uploads/imagem`, multipart com campo `image`; aceita JPG, PNG ou WEBP de até 5 MB e responde com `url` |
| Trilhas | `GET`/`POST /api/trilhas/`, `PUT`/`DELETE /api/trilhas/<id>` |
| Favoritos | `GET`/`POST /api/favoritos/`, `DELETE /api/favoritos/<id_trilha>` |
| Agendamentos | `POST /api/agendamentos/` somente para turista; listagens por usuário, guia ou agência e `PUT /api/agendamentos/<id>/cancelar` |
| Avaliações | `POST /api/avaliacoes/`; exige reserva concluída, nota válida e comentário de até 500 caracteres |
| Recuperação de senha | `POST /api/auth/senha/solicitar` e `POST /api/auth/senha/redefinir` com `token` e `nova_senha` |
| Alterar senha autenticada | `PUT /api/auth/senha` com `senha_atual` e `nova_senha` |
| Documentos profissionais | `GET`/`POST /api/documentos-profissionais/`, arquivo privado e análise administrativa |

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
- O endpoint `/api/usuarios/fcm-token` registra e remove dispositivos, com rotação de token. A central salva notificações no servidor, permite marcar como lida e respeita as preferências de push e de agendamentos. Os eventos de reservas e o teste da própria conta alimentam a central. Firebase/VAPID/service worker e o recebimento real ainda precisam de homologação com dispositivos.
- Avaliações, check-in/check-out, clima, rotas de navegação e campos de acessibilidade possuem recursos no backend e interfaces no aplicativo; as integrações externas ainda precisam de homologação.
- A rota de dashboard calcula contagens por status e valores declarados das reservas não canceladas, incluindo referências legadas por e-mail. Para agência, o recorte usa reservas das trilhas criadas por ela. O painel do frontend consome esse resumo. Os valores são informativos e não representam conciliação financeira.
- O catálogo remoto permite convidar guias. Após aceite, o guia aparece no seletor de responsável por ID. A agência pode revogar convites pendentes, reenviar convites encerrados e desligar vínculos sem reservas ativas. O guia também pode encerrar um vínculo aceito.
- A exclusão de trilha é desativação lógica. Não há migração destrutiva nem limpeza de dados legados.

Esta organização não publica nem cria commits automaticamente. Os registros antigos do frontend foram consolidados em HISTORICO.md. A documentação de rotafacil_docs foi preservada.

Contratos de guias e convites: `CONTRATOS_COMUNIDADE.md` no repositório do backend. Swagger: https://rotafacil-backend-woad.vercel.app/docs.


## Identificação da agenda de guia e agência

O frontend consulta a agenda por ID da sessão autenticada, sem repetir a chamada usando o e-mail. No backend atualizado, a mesma consulta reúne registros pelo ID e pelo e-mail atual do responsável, preservando agendamentos antigos sem duplicar resultados. A agenda direta do guia pode ser consultada somente pelo próprio guia ou por administrador. Agências usam a rota própria, que devolve apenas reservas das trilhas criadas pela conta autenticada. Essa compatibilidade depende de executar/publicar também a atualização de `services/agendamentos.py` no backend.


## Atualização de reservas e desativação de trilhas

Agenda e painéis de guia/agência consultam a API ao abrir e quando o aplicativo volta ao primeiro plano. O botão Atualizar reservas e o gesto de puxar a lista repetem a consulta. Não há assinatura em tempo real; reservas feitas em outro dispositivo aparecem após essa atualização. Falhas mantêm os dados anteriores e mostram aviso, sem indicar atualização concluída.

O cancelamento é permitido somente antes do início da atividade, nos estados pendente, agendado ou confirmado. Reservas em andamento, concluídas ou já canceladas retornam conflito e não exibem a ação na tela de detalhes.

Check-in e check-out são ações do guia responsável, da agência proprietária da trilha ou de administrador. O turista acompanha o estado e pode cancelar antes do início, mas não altera diretamente o andamento da atividade. O painel reconhece como ativas reservas pendentes, agendadas, confirmadas e em andamento.

Trilhas com reservas pendentes, confirmadas ou em andamento não podem ser desativadas. O backend retorna HTTP 409 tanto na exclusão lógica quanto na edição com ativo=false. É necessário cancelar ou concluir as reservas antes. Reservas canceladas e concluídas permanecem no histórico; nenhuma reserva é apagada em cascata. O modo demonstrativo segue a mesma regra. A validação do servidor precisa estar publicada para valer contra todos os clientes.

Criação e edição aceitam apenas os campos públicos do formulário. O servidor rejeita tentativa de alterar ID, proprietário, datas internas ou outros campos de controle. Nome, descrição, dificuldade, preço, data, booleanos, capacidade, horários, distância e coordenadas são validados na API, mesmo quando a chamada não vem do Flutter.


## Correções dos relatos de homologação

- O marcador do mapa abre os detalhes da trilha selecionada. O destaque não cria um segundo cartão na lista. Trilhas sem coordenadas válidas permanecem nos resultados comuns e não recebem marcador inventado.
- Negar localização apresenta instruções legíveis e mantém a busca por cidade e UF. O formulário de trilha também remove prefixos técnicos das mensagens.
- Distâncias aceitam vírgula decimal. O formulário exige valor positivo e finito; ausência, zero ou dados inválidos antigos aparecem como “Distância não informada”. A descrição livre não é usada para inventar a extensão. O responsável deve editar registros antigos cujo valor estruturado esteja ausente ou incorreto.
- A API de trilhas acrescenta nome_guia com o nome público do responsável localizado pelo ID ou e-mail legado. Não são acrescentados senha, documento, telefone ou dados privados do usuário. Registros sem vínculo válido mostram “Responsável não informado”. Essa identificação depende da atualização do backend.
- O painel mostra Reservas ativas e exclui canceladas e concluídas desse contador. O histórico permanece disponível na Agenda.
- Ver todas as reservas seleciona a aba da Agenda nos perfis guia e agência, preservando a navegação inferior.

Reteste os relatos no aplicativo conectado depois de atualizar ambos os repositórios. Testes automatizados usam dados e serviços isolados; não equivalem à aprovação pelos responsáveis da homologação.

## Exclusão segura da conta

A opção fica em Perfil > Privacidade e segurança e exige digitar `EXCLUIR`. O backend bloqueia a operação quando a conta participa, conduz ou administra uma atividade com reserva pendente, agendada, confirmada ou em andamento. Cancelamentos e conclusões liberam a exclusão.

Quando permitida, a exclusão remove perfil, favoritos, notificações, dispositivos FCM, disponibilidades, tokens de redefinição, documentos profissionais e convites ligados à conta. Reservas encerradas permanecem como histórico. Atividades criadas pela conta são desativadas e atribuições do guia são removidas. A sessão e o token local do dispositivo são apagados após o sucesso.

## Alteração do tipo da conta

A opção fica em Perfil > Privacidade e segurança no modo conectado. O servidor bloqueia a alteração enquanto houver reservas ativas ligadas à conta. Guia exige CPF válido e agência exige CNPJ válido. Ao deixar um perfil profissional, atividades próprias são desativadas e vínculos incompatíveis são removidos. O usuário precisa entrar novamente para abrir a home correspondente ao novo tipo.

## Alteração de senha autenticada

A tela de Privacidade e segurança usa `PUT /api/auth/senha` quando o aplicativo está conectado. O servidor confere a senha atual, exige no mínimo seis caracteres e rejeita reutilização imediata da mesma senha. O modo demonstrativo mantém a validação local.

## Documentos profissionais e administração

Guias e agências acessam Documentos profissionais no Perfil. O envio aceita imagens JPG, PNG ou WEBP de até 5 MB. A API guarda o arquivo em Firebase Storage sem URL pública e retorna apenas metadados. Somente o dono e administradores podem abrir o arquivo.

O login aceita o papel `admin` criado diretamente no backend. Esse perfil abre o painel de verificação, consulta documentos pendentes e aprova ou rejeita com motivo. A análise atualiza a situação do documento e o campo `verificado` do profissional. O backend precisa da variável `FIREBASE_STORAGE_BUCKET` e de permissão da conta de serviço no bucket.

## Central e preferências de notificações

A central consulta `GET /api/notificacoes/`, atualiza ao abrir ou puxar a lista e permite marcar uma ou todas as notificações como lidas. As preferências são armazenadas por usuário em `/api/notificacoes/preferencias`; desativar push impede a entrega ao dispositivo, e desativar avisos de agendamentos também impede que esses eventos entrem na central. Avisos de sistema continuam disponíveis na central. O recebimento em segundo plano depende da configuração real do Firebase e da chave VAPID.

## Perfil público do guia

Guias editam apresentação e especialidades em Perfil > Editar perfil. O backend limita tamanho e quantidade desses campos. Em uma trilha conduzida por guia, o turista pode abrir `GET /api/guias/<id>` e ver somente nome, foto, cidade, estado, verificação, apresentação, especialidades e as trilhas ativas já carregadas no catálogo. Documento, e-mail e telefone não entram nesse contrato público. Trilhas conduzidas diretamente por agência continuam mostrando apenas o nome do responsável.

## Validação de conta

O backend valida nome, formato do e-mail e senha de 6 a 128 caracteres mesmo quando a chamada não vem do aplicativo. Cadastro de guia aceita CPF e cadastro de agência aceita CNPJ. Alterações de perfil preservam essa compatibilidade, recusam e-mail duplicado e normalizam o endereço para minúsculas. O login devolve a mesma mensagem para conta inexistente, inativa ou senha incorreta, evitando revelar quais endereços estão cadastrados.
