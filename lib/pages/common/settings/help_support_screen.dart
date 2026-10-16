import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajuda')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Text(
          'Como usar o RotaFácil',
          style: TextStyle(
            color: AppColors.forest,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 20),
        _HelpItem(
          'Entrar e criar conta',
          'Para entrar, informe e-mail e senha. A seleção entre turista, guia e agência acontece somente ao criar uma conta.',
        ),
        _HelpItem(
          'Buscar um roteiro',
          'Em Explorar, abra a busca e selecione cidade, dificuldade, período ou proximidade. A localização é opcional.',
        ),
        _HelpItem(
          'Reservar uma atividade',
          'Abra os detalhes, confira a data e o valor informado e toque em Reservar. A operação não processa pagamento online.',
        ),
        _HelpItem(
          'Consultar e cancelar',
          'Abra Reservas para acompanhar suas atividades. Use a ação de cancelamento quando disponível e confirme a operação.',
        ),
        _HelpItem(
          'Guias e agências',
          'Gerencie atividades em Roteiros. Uma agência envia convites aos guias; o vínculo remoto depende do aceite do profissional.',
        ),
        _HelpItem(
          'Recuperar acesso',
          'Na tela de login, use Esqueci minha senha e siga as instruções de recuperação.',
        ),
      ],
    ),
  );
}

class _HelpItem extends StatelessWidget {
  const _HelpItem(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
