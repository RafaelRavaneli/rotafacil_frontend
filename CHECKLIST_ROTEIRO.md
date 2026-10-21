# Checklist do roteiro e do turista

## Organizador

Cadastro e edição do roteiro oferecem listas de itens obrigatórios e recomendados. O formulário valida até 50 itens por lista, com até 120 caracteres por item. A publicação do roteiro utiliza os campos correspondentes do backend.

## Turista

O detalhe do roteiro apresenta os itens separados por categoria. Nos detalhes da reserva, “Meu checklist” permite marcar a preparação e mostra o progresso e a quantidade de obrigatórios pendentes. A marcação é particular e vale apenas para aquela reserva.

O checklist é carregado ao abrir, ao atualizar manualmente, ao retornar à janela e quando os itens do roteiro mudam. Durante uma gravação, novas alterações aguardam a resposta. Falhas mantêm o último estado confirmado e oferecem nova tentativa. Na falha de carregamento inicial, a lista do organizador continua visível sem checkboxes que possam sugerir estado salvo.

Reservas canceladas, recusadas e concluídas exibem apenas consulta. Organizadores consultam a lista do roteiro, sem acesso ao progresso pessoal do turista. Previsão do tempo por data e rota ao destino continuam independentes do checklist.

## Persistência

No modo backend, o estado vem da API e é vinculado ao usuário autenticado e à reserva. No modo local de demonstração, SharedPreferences guarda uma chave por identidade e reserva. A exclusão local da conta limpa essas chaves. O modelo de roteiro preserva a lista de obrigatórios na serialização e aceita roteiros antigos sem esse campo.

## Estado da entrega

Implementação somente local. Publicação e homologação geral ficam para o final. O tópico seguinte não está autorizado; o checkpoint principal está em `../PRIMEIRA_VERSAO_CHECKPOINT.md`.
