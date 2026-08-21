import 'package:flutter/material.dart';

import '../services/auth_services.dart';
import '../utils/pallete.dart';
import 'login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final senhaController = TextEditingController();

  String tipoPerfil = 'guia';

  bool obscurePassword = true;
  bool carregando = false;

  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || telefone.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await AuthService.cadastrarUsuario(
        nome: nome,
        email: email,
        telefone: telefone,
        senha: senha,
        tipoPerfil: tipoPerfil,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta cadastrada com sucesso!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar a conta.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Widget campoTexto({
    required String titulo,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool senha = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Pallete.moss,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: senha ? obscurePassword : false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Pallete.herb),
            suffixIcon: senha
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Pallete.herb,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Pallete.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Pallete.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Pallete.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Pallete.herb, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget botaoPerfil({required String texto, required String valor}) {
    final selecionado = tipoPerfil == valor;

    return Expanded(
      child: SizedBox(
        height: 55,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              tipoPerfil = valor;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: selecionado ? Pallete.herb : Pallete.white,
            foregroundColor: selecionado ? Pallete.white : Pallete.moss,
            side: const BorderSide(color: Pallete.inputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criar conta',
                style: TextStyle(
                  color: Pallete.moss,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Preencha seus dados para começar.',
                style: TextStyle(color: Pallete.moss, fontSize: 16),
              ),

              const SizedBox(height: 30),

              campoTexto(
                titulo: 'Nome completo',
                hint: 'Digite seu nome completo',
                icon: Icons.person_outline,
                controller: nomeController,
              ),

              const SizedBox(height: 20),

              campoTexto(
                titulo: 'E-mail',
                hint: 'Digite seu e-mail',
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              campoTexto(
                titulo: 'Telefone',
                hint: 'Digite seu telefone',
                icon: Icons.phone_outlined,
                controller: telefoneController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              campoTexto(
                titulo: 'Senha',
                hint: 'Digite sua senha',
                icon: Icons.lock_outline,
                controller: senhaController,
                senha: true,
              ),

              const SizedBox(height: 25),

              const Text(
                'Tipo de conta',
                style: TextStyle(
                  color: Pallete.moss,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  botaoPerfil(texto: 'Guia', valor: 'guia'),

                  const SizedBox(width: 8),

                  botaoPerfil(texto: 'Turista', valor: 'turista'),

                  const SizedBox(width: 8),

                  botaoPerfil(texto: 'Agência', valor: 'agencia'),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: carregando ? null : cadastrar,
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
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Já tem conta? Entrar',
                    style: TextStyle(
                      color: Pallete.herb,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
