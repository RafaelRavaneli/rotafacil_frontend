import 'package:flutter/material.dart';

import '../utils/pallete.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() =>
      _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final emailController = TextEditingController();

  bool carregando = false;

  Future<void> recuperarSenha() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite seu e-mail.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) return;

    setState(() {
      carregando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitação de recuperação enviada!',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        elevation: 0,
        title: const Text(
          'Recuperar senha',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            const Center(
              child: Icon(
                Icons.lock_reset_outlined,
                size: 90,
                color: Pallete.herb,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Esqueceu sua senha?',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Digite o e-mail cadastrado para recuperar o acesso à sua conta.',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 16,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'E-mail',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Digite seu e-mail',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Pallete.herb,
                ),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Pallete.inputBorder,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: carregando ? null : recuperarSenha,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.herb,
                  foregroundColor: Pallete.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: carregando
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Pallete.white,
                        ),
                      )
                    : const Text(
                        'Recuperar senha',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Voltar para o login',
                  style: TextStyle(
                    color: Pallete.herb,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}