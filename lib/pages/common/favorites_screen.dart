import 'package:flutter/material.dart';
import '../../utils/run_action.dart';
import '../../state/app_store.dart';
import '../../widgets/trail_card.dart';
import '../tourist/trail_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final trails = store.favoriteTrails;
          if (trails.isEmpty) {
            return const Center(
              child: Text('Você ainda não favoritou nenhuma trilha.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: trails.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final trail = trails[index];
              return TrailCard(
                trail: trail,
                favorite: true,
                onFavorite: () =>
                    runAction(context, () => store.toggleFavorite(trail.id)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrailDetailsScreen(trail: trail),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
