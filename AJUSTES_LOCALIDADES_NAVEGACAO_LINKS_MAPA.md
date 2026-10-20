# Localidades, navegação, autenticação por link e mapa

## Localidades

O componente compartilhado posiciona UF à esquerda e cidade à direita. A UF tem largura própria, ícone compacto e preenchimento controlado; ambos os campos usam texto escuro explícito para não herdar a cor clara do formulário de autenticação. O seletor continua utilizando os municípios oficiais e limpa a cidade ao mudar de estado.

## Navegação

Trocas de aba e etapas do cadastro renderizam apenas o conteúdo atual durante a animação. A escala foi removida da troca de abas e os tempos de animação do cadastro foram sincronizados. `AppRoutes.push` evita empilhar duas páginas quando a primeira navegação já começou. A mesma proteção foi aplicada à entrada, seleção de perfil e abertura de telas do perfil. Login e cadastro rejeitam reenvio enquanto processam a ação.

## Links de autenticação

Confirmação de e-mail e recuperação de senha passam a enviar links. As páginas `/confirmar-email` e `/redefinir-senha` são resolvidas antes de exigir sessão. Os links destinados ao aplicativo web usam o fragmento `/#/...`, incluindo o segredo apenas nesse fragmento, não na query enviada ao servidor HTTP.

A tela captura os dados em memória, remove os parâmetros da URL e mantém um nome de rota sem segredo. Uma confirmação explícita consome o link por POST. Apenas abrir a URL não modifica a conta. A confirmação entra na conta; a recuperação exige duas entradas da nova senha antes de salvar e entrar. Links inválidos, usados ou expirados permitem solicitar outro link.

Após a API retornar uma sessão válida, a sessão é persistida e o usuário segue à Home correspondente ao perfil. Uma falha temporária na carga da Home permite tentar continuar sem consumir novamente o link já usado. O envio das notificações e a localização continuam opcionais.

Estes links abrem o aplicativo web. Associação de domínio a aplicativos nativos Android/iOS não foi adicionada nesta etapa.

## Mapa de resultados

Marcadores que ficariam a menos de 60 pixels entre si são agrupados conforme o zoom. O marcador mostra a quantidade. Ao tocar, uma lista permite escolher o roteiro. Ampliar o mapa separa posições próximas; posições coincidentes continuam agrupadas. Roteiros sem coordenadas válidas permanecem apenas na lista de resultados, sem posição inventada.

## Estado

Alterações locais, sem publicação. Os e-mails reais com os novos links só devem ser homologados depois da publicação coordenada do frontend e backend, quando autorizada. Testes locais utilizam APIs e envio de e-mail simulados.
