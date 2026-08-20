import 'package:flutter/material.dart';

import '../utils/pallete.dart';
import 'home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  String tipoConta = 'guia';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 55, 25, 25),
              color: Pallete.herb,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar Conta',
                    style: TextStyle(
                      color: Pallete.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Junte-se à comunidade de guias',
                    style: TextStyle(
                      color: Pallete.pearl,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Foto
            Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Pallete.inputBorder,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Pallete.herb,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Pallete.herb,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Pallete.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  const Text(
                    'Nome completo',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Digite seu nome completo',
                      prefixIcon: const Icon(
                        Icons.person_outline,
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Pallete.inputBorder,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Pallete.inputBorder,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Telefone
                  const Text(
                    'Telefone',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Digite seu telefone',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Pallete.inputBorder,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

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
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Digite sua senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Pallete.inputBorder,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Tipo de conta
                  const Text(
                    'Tipo de conta',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // GUIA
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              tipoConta = 'guia';
                            });
                          },
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: tipoConta == 'guia'
                                  ? Pallete.herb
                                  : Pallete.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Pallete.inputBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Guia',
                                style: TextStyle(
                                  color: tipoConta == 'guia'
                                      ? Pallete.white
                                      : Pallete.moss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // TURISTA
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              tipoConta = 'turista';
                            });
                          },
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: tipoConta == 'turista'
                                  ? Pallete.herb
                                  : Pallete.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Pallete.inputBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Turista',
                                style: TextStyle(
                                  color: tipoConta == 'turista'
                                      ? Pallete.white
                                      : Pallete.moss,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // AGÊNCIA
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              tipoConta = 'agencia';
                            });
                          },
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: tipoConta == 'agencia'
                                  ? Pallete.herb
                                  : Pallete.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Pallete.inputBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Agência',
                                style: TextStyle(
                                  color: tipoConta == 'agencia'
                                      ? Pallete.white
                                      : Pallete.moss,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Botão cadastrar
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
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
                        'Cadastrar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Já possui conta
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}