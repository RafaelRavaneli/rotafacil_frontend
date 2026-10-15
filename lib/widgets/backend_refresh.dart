import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../state/app_store.dart';
import '../utils/auth_error_message.dart';

/// Atualiza dados ao abrir a tela, retornar ao app ou solicitar nova consulta.
class BackendRefresh extends StatefulWidget {
  const BackendRefresh({super.key, required this.child, this.onRefresh});
  final Widget child;
  final Future<void> Function()? onRefresh;
  @override
  State<BackendRefresh> createState() => _BackendRefreshState();
}

class _BackendRefreshState extends State<BackendRefresh>
    with WidgetsBindingObserver {
  bool loading = false;
  String? error;
  bool get available =>
      widget.onRefresh != null ||
      (AppStore.instance.useBackend &&
          (SessionService.instance.userId?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && available) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && available) _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted || loading || !available) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await (widget.onRefresh ?? AppStore.instance.refreshBackend)();
    } catch (failure) {
      if (mounted) setState(() => error = authErrorMessage(failure));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!available) return widget.child;
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: loading ? null : _refresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  loading ? 'Atualizando reservas...' : 'Atualizar reservas',
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Não foi possível atualizar as reservas. $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, child: widget.child),
          ),
        ],
      ),
    );
  }
}
