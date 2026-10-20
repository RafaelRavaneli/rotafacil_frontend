import 'package:flutter/material.dart';
import '../services/brazil_locations.dart';

class BrazilLocationFields extends StatelessWidget {
  const BrazilLocationFields({
    super.key,
    required this.city,
    required this.state,
    this.onChanged,
    this.enabled = true,
    this.labelsAbove = false,
    this.labelStyle,
  });
  final TextEditingController city;
  final TextEditingController state;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool labelsAbove;
  final TextStyle? labelStyle;

  Future<void> _choose(BuildContext context, bool choosingState) async {
    try {
      final states = await BrazilLocations.load();
      if (!context.mounted) return;
      final selectedState = BrazilLocations.findState(states, state.text);
      if (!choosingState && selectedState == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione a UF antes da cidade.')),
        );
        return;
      }
      final values = choosingState
          ? states.map((s) => '${s.uf} — ${s.name}').toList()
          : selectedState!.cities;
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => _LocationPicker(
          title: choosingState ? 'Selecionar estado' : 'Selecionar cidade',
          values: values,
        ),
      );
      if (selected == null || !context.mounted) return;
      if (choosingState) {
        final uf = selected.split(' — ').first;
        if (state.text != uf) city.clear();
        state.text = uf;
      } else {
        city.text = selected;
      }
      onChanged?.call();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar as localidades. Tente novamente.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(
      String label,
      TextEditingController controller,
      bool choosingState,
    ) {
      final input = TextField(
        controller: controller,
        style: labelsAbove
            ? const TextStyle(color: Color(0xFF25332C), fontSize: 14)
            : null,
        readOnly: true,
        enabled: enabled,
        onTap: () => _choose(context, choosingState),
        decoration: InputDecoration(
          labelText: labelsAbove ? null : label,
          hintText: choosingState ? 'UF' : 'Selecione a cidade',
          filled: labelsAbove ? true : null,
          fillColor: labelsAbove ? const Color(0xFFFFFEF7) : null,
          isDense: labelsAbove,
          border: labelsAbove
              ? OutlineInputBorder(borderRadius: BorderRadius.circular(9))
              : null,
          suffixIcon: const Icon(Icons.expand_more),
        ),
      );
      return labelsAbove
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                const SizedBox(height: 6),
                input,
              ],
            )
          : input;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: field('Cidade', city, false)),
        const SizedBox(width: 10),
        Expanded(child: field('UF', state, true)),
      ],
    );
  }
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({required this.title, required this.values});
  final String title;
  final List<String> values;
  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final values = widget.values
        .where(
          (v) => BrazilLocations.normalize(
            v,
          ).contains(BrazilLocations.normalize(query)),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title),
              trailing: IconButton(
                tooltip: 'Fechar',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: values.isEmpty
                  ? const Center(child: Text('Nenhum resultado encontrado.'))
                  : ListView.builder(
                      itemCount: values.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(values[index]),
                        onTap: () => Navigator.pop(context, values[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
