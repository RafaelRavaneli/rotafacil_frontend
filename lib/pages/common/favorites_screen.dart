import 'package:flutter/material.dart';
import '../../utils/run_action.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trail_card.dart';
import '../../navigation/app_routes.dart';
import '../tourist/trail_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final trails = store.favoriteTrails;
            if (trails.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Text(
                      'Favoritos',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Spacer(),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.sage,
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 38,
                              color: AppColors.forest,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Nenhum roteiro salvo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Toque no coração de um roteiro para encontrá-lo aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Spacer(flex: 2),
                  ],
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                return CustomScrollView(
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 30, 24, 24),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Favoritos',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                      sliver: SliverGrid.builder(
                        itemCount: trails.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 22,
                          childAspectRatio: .82,
                        ),
                        itemBuilder: (context, index) {
                          final trail = trails[index];
                          return TrailCard(
                            trail: trail,
                            favorite: true,
                            onFavorite: () => runAction(
                              context,
                              () => store.toggleFavorite(trail.id),
                            ),
                            onTap: () => AppRoutes.push(
                              context,
                              AppRoutes.trail(trail.id),
                              (_) => TrailDetailsScreen(trail: trail),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
