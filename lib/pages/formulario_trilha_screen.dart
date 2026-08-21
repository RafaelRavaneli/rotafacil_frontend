import 'package:flutter/material.dart';

import '../utils/pallete.dart';

class FormularioTrilhaScreen extends StatefulWidget {
  const FormularioTrilhaScreen({super.key});

  @override
  State<FormularioTrilhaScreen> createState() =>
      _FormularioTrilhaScreenState();
}

class _FormularioTrilhaScreenState
    extends State<FormularioTrilhaScreen> {
  final nomeController = TextEditingController();
  final descricaoController = TextEditingController();
  final cidadeController = TextEditingController();
  final estadoController = TextEditingController();
  final pontoEncontroController = TextEditingController();

  String? dificuldade;
  DateTime? dataSelecionada;

  final dificuldades = [
    'Fácil',
    'Moderada',
    'Difícil',
  ];

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

  String formatarData() {
    if (dataSelecionada == null) {
      return 'Selecionar data';
    }

    final dia =
        dataSelecionada!.day.toString().padLeft(2, '0');
    final mes =
        dataSelecionada!.month.toString().padLeft(2, '0');

    return '$dia/$mes/${dataSelecionada!.year}';
  }

  void salvarTrilha() {
    if (nomeController.text.isEmpty ||
        descricaoController.text.isEmpty ||
        cidadeController.text.isEmpty ||
        estadoController.text.isEmpty ||
        pontoEncontroController.text.isEmpty ||
        dificuldade == null ||
        dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Trilha salva com sucesso!',
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nomeController.dispose();
    descricaoController.dispose();
    cidadeController.dispose();
    estadoController.dispose();
    pontoEncontroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.pearl,
      appBar: AppBar(
        backgroundColor: Pallete.herb,
        foregroundColor: Pallete.white,
        title: const Text(
          'Nova Trilha',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações da trilha',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            _campo(
              controller: nomeController,
              titulo: 'Nome da trilha',
              hint: 'Ex: Trilha da Cachoeira',
              icon: Icons.landscape_outlined,
            ),

            const SizedBox(height: 18),

            const Text(
              'Descrição',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: descricaoController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Descreva a trilha...',
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

            const SizedBox(height: 18),

            _campo(
              controller: cidadeController,
              titulo: 'Cidade',
              hint: 'Ex: Maringá',
              icon: Icons.location_city_outlined,
            ),

            const SizedBox(height: 18),

            _campo(
              controller: estadoController,
              titulo: 'Estado',
              hint: 'Ex: PR',
              icon: Icons.map_outlined,
            ),

            const SizedBox(height: 18),

            const Text(
              'Dificuldade',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: dificuldade,
              hint: const Text('Selecione'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Pallete.white,
                prefixIcon: const Icon(
                  Icons.hiking,
                  color: Pallete.herb,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: dificuldades.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  dificuldade = valor;
                });
              },
            ),

            const SizedBox(height: 18),

            _campo(
              controller: pontoEncontroController,
              titulo: 'Ponto de encontro',
              hint: 'Ex: Entrada do Parque Municipal',
              icon: Icons.place_outlined,
            ),

            const SizedBox(height: 18),

            const Text(
              'Data da trilha',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: selecionarData,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Pallete.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Pallete.inputBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Pallete.herb,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatarData(),
                      style: const TextStyle(
                        color: Pallete.moss,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Imagem temporária
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Pallete.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Pallete.inputBorder,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Pallete.herb,
                    size: 45,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Selecionar imagem da trilha',
                    style: TextStyle(
                      color: Pallete.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'O envio da imagem será conectado ao backend depois.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Pallete.moss,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: salvarTrilha,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.herb,
                  foregroundColor: Pallete.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Salvar trilha',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String titulo,
    required String hint,
    required IconData icon,
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
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
      ],
    );
  }
}