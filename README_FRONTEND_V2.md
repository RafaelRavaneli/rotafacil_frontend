# RotaFácil Front-end V2 — fluxo completo sem backend

Esta versão foi reestruturada para que todas as principais telas e interações funcionem no próprio front-end.

## Incluído

### Todos os perfis
- editar perfil
- dados pessoais
- notificações
- privacidade e segurança
- ajuda e suporte
- sair da conta

### Turista
- home
- busca de trilhas
- filtro por nome/cidade/estado
- filtro por dificuldade
- filtro por distância do percurso
- detalhes da trilha
- agendamento
- cancelamento de agendamento
- tela de agendamentos
- perfil completo

### Guia
- dashboard
- lista de trilhas
- adicionar trilha
- adicionar foto da trilha com `image_picker`
- excluir trilha
- tela de agendamentos
- perfil completo

### Agência
- dashboard
- lista de guias
- convidar guia
- ativar/remover guia
- lista de trilhas
- adicionar trilha
- selecionar guia responsável
- adicionar foto
- agendamentos
- perfil completo

## Importante

Tudo funciona localmente usando `AppStore`, portanto esta versão não depende do backend para demonstração.

Os dados ficam em memória durante a execução. Ao fechar totalmente o aplicativo, os dados adicionados durante o teste são reiniciados.

## Para rodar

```bash
flutter pub get
flutter analyze
flutter run -d chrome
```
