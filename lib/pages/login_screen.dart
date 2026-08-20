import 'package:flutter/material.dart';

import '../utils/pallete.dart';
import 'create_account_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(25, 55, 25, 30),
                color: Pallete.herb,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        color: Pallete.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Entre na sua conta para continuar',
                      style: TextStyle(color: Pallete.pearl, fontSize: 17),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 45),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // E-mail
                    const Text(
                      'E-mail',
                      style: TextStyle(
                        color: Pallete.moss,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
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

                    const SizedBox(height: 20),

                    // Senha
                    const Text(
                      'Senha',
                      style: TextStyle(
                        color: Pallete.moss,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Pallete.herb,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Pallete.herb,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
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

                    const SizedBox(height: 12),

                    // Esqueci a senha
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Futuramente implementar recuperação de senha.
                        },
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            color: Pallete.herb,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Botão entrar
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          // Temporariamente entra direto na Home.
                          // Depois substituiremos pela chamada à API.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Pallete.herb,
                          foregroundColor: Pallete.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Cadastro
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAccountScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Não possui uma conta? Cadastre-se',
                          style: TextStyle(
                            color: Pallete.herb,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
