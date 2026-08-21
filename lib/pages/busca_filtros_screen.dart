import 'package:flutter/material.dart';

import '../utils/pallete.dart';
import 'detalhes_trilha_screen.dart';

class BuscaFiltrosScreen extends StatefulWidget {
  const BuscaFiltrosScreen({super.key});

  @override
  State<BuscaFiltrosScreen> createState() => _BuscaFiltrosScreenState();
}

class _BuscaFiltrosScreenState extends State<BuscaFiltrosScreen> {
  final TextEditingController _cidadeController = TextEditingController();

  String? _dificuldade;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final List<String> _dificuldades = ['Fácil', 'Moderada', 'Difícil'];

  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        _dataInicio = data;

        if (_dataFim != null && _dataFim!.isBefore(data)) {
          _dataFim = null;
        }
      });
    }
  }

  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: _dataInicio ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        _dataFim = data;
      });
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Selecionar';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  void _buscar() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros aplicados!')));
  }

  void _limparFiltros() {
    setState(() {
      _cidadeController.clear();
      _dificuldade = null;
      _dataInicio = null;
      _dataFim = null;
    });
  }

  @override
  void dispose() {
    _cidadeController.dispose();
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
          'Buscar Trilhas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Encontre sua próxima aventura',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Use os filtros para encontrar a trilha ideal para você.',
              style: TextStyle(color: Pallete.moss, fontSize: 16),
            ),

            const SizedBox(height: 30),

            // Cidade
            const Text(
              'Cidade',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _cidadeController,
              decoration: InputDecoration(
                hintText: 'Ex: Maringá',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Pallete.herb,
                ),
                filled: true,
                fillColor: Pallete.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Dificuldade
            const Text(
              'Nível de dificuldade',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _dificuldade,
              decoration: InputDecoration(
                filled: true,
                fillColor: Pallete.white,
                prefixIcon: const Icon(Icons.hiking, color: Pallete.herb),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              hint: const Text('Selecione'),
              items: _dificuldades.map((dificuldade) {
                return DropdownMenuItem<String>(
                  value: dificuldade,
                  child: Text(dificuldade),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  _dificuldade = valor;
                });
              },
            ),

            const SizedBox(height: 25),

            // Período
            const Text(
              'Período',
              style: TextStyle(
                color: Pallete.moss,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _botaoData(
                    titulo: 'Data inicial',
                    data: _dataInicio,
                    onPressed: _selecionarDataInicio,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _botaoData(
                    titulo: 'Data final',
                    data: _dataFim,
                    onPressed: _selecionarDataFim,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            // Botão buscar
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.search),
                label: const Text(
                  'Buscar trilhas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.herb,
                  foregroundColor: Pallete.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Limpar filtros
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _limparFiltros,
                child: const Text(
                  'Limpar filtros',
                  style: TextStyle(color: Pallete.moss, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Trilhas encontradas
            const Text(
              'Trilhas encontradas',
              style: TextStyle(
                color: Pallete.moss,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _trilhaCard(
              context,
              nome: 'Trilha da Cachoeira',
              cidade: 'Maringá',
              estado: 'PR',
              dificuldade: 'Moderada',
              data: '25/08/2026',
              descricao:
                  'Passeio por uma trilha cercada por natureza, com percurso agradável e visita a uma cachoeira.',
              pontoEncontro: 'Parque Municipal',
            ),

            const SizedBox(height: 15),

            _trilhaCard(
              context,
              nome: 'Trilha do Mirante',
              cidade: 'Londrina',
              estado: 'PR',
              dificuldade: 'Fácil',
              data: '02/09/2026',
              descricao:
                  'Trilha leve com vista panorâmica, indicada para quem busca um passeio tranquilo em contato com a natureza.',
              pontoEncontro: 'Entrada do Parque',
            ),

            const SizedBox(height: 15),

            _trilhaCard(
              context,
              nome: 'Trilha da Serra',
              cidade: 'Apucarana',
              estado: 'PR',
              dificuldade: 'Difícil',
              data: '10/09/2026',
              descricao:
                  'Percurso mais intenso, com subidas e trechos de maior dificuldade, recomendado para pessoas com experiência.',
              pontoEncontro: 'Centro de Visitantes',
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _botaoData({
    required String titulo,
    required DateTime? data,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Pallete.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(color: Pallete.moss, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: Pallete.herb,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatarData(data),
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trilhaCard(
    BuildContext context, {
    required String nome,
    required String cidade,
    required String estado,
    required String dificuldade,
    required String data,
    required String descricao,
    required String pontoEncontro,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalhesTrilhaScreen(
              nome: nome,
              descricao: descricao,
              cidade: cidade,
              estado: estado,
              dificuldade: dificuldade,
              pontoEncontro: pontoEncontro,
              data: data,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Pallete.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Pallete.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Pallete.inputBorder,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: Pallete.herb,
                size: 38,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      color: Pallete.moss,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$cidade - $estado',
                    style: const TextStyle(color: Pallete.moss),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$dificuldade • $data',
                    style: const TextStyle(
                      color: Pallete.herb,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Pallete.herb),
          ],
        ),
      ),
    );
  }
}
