# Seleção de cidade e estado

Cadastro, edição do perfil, cadastro/edição de roteiros e filtros de pesquisa usam o componente compartilhado `BrazilLocationFields`.

O usuário seleciona uma UF e pesquisa uma cidade da lista correspondente. A busca ignora acentos e maiúsculas. Apenas os resultados podem ser selecionados. Trocar a UF limpa a cidade anterior. Os valores já cadastrados são preservados até uma nova seleção.

O catálogo fica em `assets/data/brazil_locations.json` e funciona sem acesso à internet. Fonte: API oficial de localidades do IBGE, consultada em 20/10/2026:

- https://servicodados.ibge.gov.br/api/v1/localidades/estados
- https://servicodados.ibge.gov.br/api/v1/localidades/municipios

São 27 UFs e 5.571 municípios. Para atualizar o catálogo, agrupar os municípios por UF, considerando tanto microrregião/mesorregião quanto região imediata/intermediária. Preservar nomes oficiais e ordenar as cidades.

O preenchimento por endereço no mapa reconhece o nome completo do estado e só preenche cidades pertencentes à UF. Não corta mais os primeiros dois caracteres do nome do estado.

Validação: análise estática e testes de localidades, cadastro, dados pessoais e telas de operadores. Alteração local; publicação pendente.
