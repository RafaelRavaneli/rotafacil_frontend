import 'package:flutter/material.dart';
import 'pallete.dart';
import 'create_account_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.herb,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 40,
          ),
          child: Column(
            children: [
              const Spacer(),

              // Ícone
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: Pallete.pearl,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 60,
                  color: Pallete.herb,
                ),
              ),

              const SizedBox(height: 35),

              // Nome do aplicativo
              const Text(
                'RotaFácil',
                style: TextStyle(
                  color: Pallete.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Guias. Trilhas. Aventuras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Pallete.pearl,
                  fontSize: 20,
                ),
              ),

              const Spacer(),

              // Botão Começar
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context)=> const CreateAccountScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.pearl,
                    foregroundColor: Pallete.herb,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Começar →',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Indicador das páginas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Pallete.pearl,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Pallete.inputBorder,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Pallete.inputBorder,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}