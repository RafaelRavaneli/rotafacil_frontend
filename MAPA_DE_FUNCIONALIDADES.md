# Checklist funcional — RotaFácil V3

## Entrada
- [x] Boas-vindas
- [x] Escolha Turista / Guia / Agência
- [x] Login com senha
- [x] Cadastro
- [x] Esqueci minha senha
- [x] Logout

## Turista
- [x] Home
- [x] Lista de trilhas
- [x] Abrir detalhes
- [x] Favoritar / desfavoritar
- [x] Tela de favoritos
- [x] Busca por cidade
- [x] Busca por estado
- [x] Filtro por dificuldade
- [x] Filtro por período
- [x] Permissão de GPS
- [x] Busca por proximidade
- [x] Raio 5–100 km
- [x] Ordenação pela distância ao usuário
- [x] Agendar trilha
- [x] Ver agendamentos
- [x] Cancelar agendamento
- [x] Mensagens

## Guia
- [x] Dashboard
- [x] Indicadores
- [x] Ver agenda
- [x] Criar trilha
- [x] Editar trilha
- [x] Excluir trilha
- [x] Selecionar foto
- [x] Definir localização por GPS
- [x] Modalidade
- [x] Dificuldade
- [x] Distância
- [x] Data
- [x] Preço
- [x] Mensagens

## Agência
- [x] Dashboard
- [x] Indicadores
- [x] Convidar guia
- [x] Ativar guia
- [x] Marcar guia pendente
- [x] Remover guia
- [x] Criar trilha
- [x] Editar trilha
- [x] Excluir trilha
- [x] Selecionar guia responsável
- [x] Foto
- [x] GPS
- [x] Agendamentos

## Perfil — todos
- [x] Editar perfil
- [x] Dados pessoais
- [x] Alterar e-mail de login local
- [x] Notificações
- [x] Central de notificações
- [x] Notificação local de teste
- [x] Privacidade
- [x] Alterar senha
- [x] Sessão atual
- [x] Ajuda e suporte

## Firebase Cloud Messaging
- [x] firebase_core
- [x] firebase_messaging
- [x] pedir permissão
- [x] getToken()
- [x] onTokenRefresh
- [x] POST /api/usuarios/fcm-token quando backend JWT estiver ativo
- [x] DELETE /api/usuarios/fcm-token no logout
- [x] onMessage (foreground)
- [x] onMessageOpenedApp
- [x] getInitialMessage
- [x] handler de background Android/iOS
- [x] service worker Web fornecido como template

## Persistência
- [x] Perfil
- [x] Guias
- [x] Trilhas
- [x] Agendamentos
- [x] Favoritos
- [x] Mensagens
- [x] Configurações
- [x] Notificações

Os itens de Firebase que dependem de comunicação real com o FCM exigem as
credenciais do projeto Firebase do time. O código não pode inventar essas credenciais.
