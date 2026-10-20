# Checkpoint de correções dos relatos do Trello — 20/10/2026

## Backend

Commit: `d3bc5dc`.

- Criação de convite notifica o guia; aceite/recusa notificam a agência. Reenvio, revogação e encerramento do vínculo notificam a outra parte. Eventos usam a central existente e o envio push existente. Falha de push não desfaz a operação.
- Nova solicitação de reserva também gera aviso para o turista, informando que aguarda confirmação. Resposta e finalização respeitam a preferência de notificações de agendamentos.
- Catálogo e perfil público do guia retornam média e quantidade reais de avaliações.
- Falha no envio do e-mail remove o token recém-criado, permitindo nova tentativa. Antes, o token não entregue bloqueava tentativas por 30 minutos. SMTP tem tempo limite de 15 segundos.
- 81 testes passaram, sem usar banco ou envio externo reais.

## Frontend

- Perfil público usa e exibe a média real do guia.
- Carrossel e cartão incluem notas zero quando há avaliações. Roteiros sem avaliações continuam fora do carrossel.
- Localização recente só é reutilizada depois de consultar a permissão atual e verificar o serviço. Revogação de permissão não mantém resultados baseados no cache anterior.
- Central de notificações atualiza ao abrir, oferece acesso às preferências e permite atualizar a lista vazia. Erros de leitura e alteração têm tratamento visível.
- Preferências explicam permissão de push negada e preservam acesso à central. Avisos não exibem detalhes técnicos do FCM.
- Reserva ativa explica que a avaliação depende da finalização pelo responsável. A regra de liberar avaliação somente após conclusão permanece.
- 99 testes passaram; 5 testes já estão ignorados pelo modo de execução. Análise estática sem problemas.

## Regressões verificadas sem nova alteração de regra

- URL direta abre roteiro, edição e inscritos, preservando a tela solicitada.
- Regressões de volta, dados não salvos, permissões de agência/guia, convites, finalização e cadastro passaram.
- URL de foto restaurada é preservada pelo modelo e usada pelo avatar; estratégia de exibição web existente permanece. O reteste visual em navegador com as fotos utilizadas pelos testadores continua necessário, pois estes testes não validam a hospedagem real das imagens.
- Atividades múltiplas no detalhe já eram cobertas pelo contrato. Carrossel atual de cachoeiras permanece conforme pedido do usuário.

## Pendências externas

- SMTP: configurar `EMAIL_REMETENTE` e `EMAIL_SENHA_APP` no backend hospedado e confirmar recebimento em conta real. Não inserir credenciais no repositório nem em comentários do Trello.
- FCM: confirmar credenciais, permissão do navegador/dispositivo, registro da instalação e recebimento real em primeiro e segundo plano. Persistência na central não comprova recebimento de push.
- Testadores precisam registrar os retestes na nova versão. Checklists do Trello não foram marcados como aprovados automaticamente.

Alterações locais, ainda sem publicação.
