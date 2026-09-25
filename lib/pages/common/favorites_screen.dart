import 'package:flutter/material.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../tourist/trail_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trilhas favoritas',
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
              return ListTile(
                tileColor: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: SizedBox(
                  width: 64,
                  height: 54,
                  child: NetworkImageBox(url: trail.imageUrl, borderRadius: 10),
                ),
                title: Text(
                  trail.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(trail.location),
                trailing: IconButton(
                  onPressed: () => store.toggleFavorite(trail.id),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.red,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailDetailsScreen(trail: trail),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
