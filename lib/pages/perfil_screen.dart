import 'package:flutter/material.dart';

import '../utils/pallete.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
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
          'Meu Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Foto do perfil
            Stack(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Pallete.inputBorder,
                  child: Icon(
                    Icons.person,
                    size: 65,
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
                      Icons.edit,
                      color: Pallete.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Nome
            TextFormField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Pallete.herb,
                ),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Email
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Pallete.herb,
                ),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Telefone
            TextFormField(
              controller: telefoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone',
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: Pallete.herb,
                ),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Salvar
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Perfil atualizado com sucesso!',
                      ),
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
                  'Salvar alterações',
                  style: TextStyle(
                    fontSize: 18,
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