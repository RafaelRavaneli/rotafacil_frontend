# Termos de uso e política de privacidade

## Acesso

As páginas `/termos` e `/privacidade` são públicas e funcionam mesmo sem sessão. Há links na tela inicial, no cadastro e em Privacidade e segurança. O botão de voltar respeita a navegação existente; para uma URL aberta sem histórico, retorna à entrada do aplicativo.

Os textos ficam em `assets/data/legal_documents.json`. A versão e o responsável são apresentados junto aos documentos. O usuário pode selecionar e copiar o conteúdo, inclusive o e-mail de atendimento.

## Aceite

O checkbox do cadastro começa desmarcado. O usuário deve aceitar os Termos de Uso e declarar ciência da Política de Privacidade. O frontend transmite os indicadores e versões; o backend valida e registra a prova com seu próprio horário. As permissões opcionais não são alteradas pelo aceite.

Contas existentes podem abrir os documentos pelo perfil e usar “Registrar aceite na minha conta”, com confirmação explícita. Essa ação só aparece quando o backend está habilitado e há sessão autenticada. A abertura do documento, por si só, não registra aceite.

No modo de demonstração local, o cadastro guarda os dados de aceite na conta local; esse registro não representa prova persistida no servidor.

## Manutenção

Sincronizar o conteúdo com `rotafacil_backend_work/legal/legal_documents.json`. Cada versão precisa identificar um único conteúdo. A API rejeita versões diferentes das atuais; versões novas devem ser apresentadas ao usuário antes de um novo aceite.

Testes verificam hashes, leitura pública, URLs diretas sem login, bloqueio do cadastro sem aceite e envio das versões no modo backend usando API simulada.

As alterações desta etapa permanecem locais e não foram publicadas.
