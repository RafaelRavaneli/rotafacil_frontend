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

## V5 — Guias clicáveis
- Os cards em **Guias disponíveis** agora são clicáveis.
- Cursor muda para mãozinha no Chrome/Web.
- Tela pública do guia com foto, verificação, nota, avaliações, especialidades, experiência, trilhas concluídas e quilômetros guiados.
- Botão **Conversar com o guia** abre uma conversa vinculada ao guia selecionado.
- As conversas com guias diferentes ficam separadas localmente.
- As trilhas daquele guia aparecem dentro do perfil e são clicáveis.
- Em **Detalhes da trilha**, o bloco **Guia responsável** também abre o perfil do guia.
