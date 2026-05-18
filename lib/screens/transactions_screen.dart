import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final txState = ref.watch(transactionsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _GlassAppBar(ref: ref),
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          txState.when(
            data: (txs) => _TransactionList(transactions: txs, ref: ref),
            loading: () => const _GlassLoading(),
            error: (err, _) => _GlassError(message: '$err', ref: ref),
          ),
        ],
      ),
    );
  }
}

// 📜 LISTA DE TRANSACCIONES CON PADDING CALCULADO (SIN SUPERPOSICIÓN)
class _TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final WidgetRef ref;
  const _TransactionList({required this.transactions, required this.ref});

  @override
  Widget build(BuildContext context) {
    // ✅ Cálculo exacto de la altura del header: SafeArea + PreferredSize + Padding interno
    final headerHeight = MediaQuery.of(context).padding.top + 15;
    final hasMore = ref.watch(transactionsProvider.notifier).hasMore;
    final isLoading = ref.watch(transactionsProvider).isLoading;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: headerHeight),
          child: Text(
            'No hay movimientos registrados',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200 &&
            hasMore &&
            !isLoading) {
          ref.read(transactionsProvider.notifier).loadMore();
        }
        return true;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            // ✅ Top padding dinámico que respeta exactamente la zona del header
            padding: EdgeInsets.only(
              top: headerHeight,
              bottom: 100,
              left: 16,
              right: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                if (i == transactions.length) {
                  return hasMore && isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : hasMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Desliza para cargar más...',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                return _TransactionCard(
                  tx: transactions[i],
                  index: i,
                ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.1);
              }, childCount: transactions.length + (hasMore ? 1 : 0)),
            ),
          ),
        ],
      ),
    );
  }
}

// 🃏 TARJETA DE TRANSACCIÓN (Sin errores de scope/context)
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final int index;
  const _TransactionCard({required this.tx, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = tx['type'] as String? ?? 'UNKNOWN';
    final qtyChange = tx['quantity_change'] as int? ?? 0;
    final createdAt = tx['created_at'] as String? ?? '';
    final product = tx['product'] as Map<String, dynamic>?;
    final warehouse = tx['warehouse'] as Map<String, dynamic>?;
    final user = tx['user'] as Map<String, dynamic>?;
    final notes = tx['notes'] as String? ?? '';

    final (icon, color) = _getTypeStyle(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipPath(
        clipper: _GlassClipTx(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.15),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product?['name'] ?? 'Producto desconocido',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${product?['sku'] ?? '---'}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 ${warehouse?['name'] ?? 'Almacén principal'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '👤 ${user?['name'] ?? user?['email'] ?? 'Sistema'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${qtyChange > 0 ? '+' : ''}$qtyChange uds',
                          style: TextStyle(
                            color: qtyChange > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notes,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getTypeStyle(String type) {
    return switch (type.toUpperCase()) {
      'INITIAL' => (Icons.add_circle_outlined, const Color(0xFF00E676)),
      'ADJUST' => (Icons.edit_outlined, const Color(0xFFFFB74D)),
      'RECEIVE' => (Icons.download_outlined, const Color(0xFF42A5F5)),
      'PICK' => (Icons.remove_circle_outlined, const Color(0xFFEF5350)),
      'DRAW' => (Icons.shopping_bag_outlined, const Color(0xFFAB47BC)),
      'TRANSFER' => (Icons.swap_horiz_outlined, const Color(0xFF26C6DA)),
      _ => (Icons.history_outlined, Colors.grey),
    };
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0)
        return 'Hoy ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (diff.inDays == 1)
        return 'Ayer ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _GlassClipTx extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * 0.85)
    ..lineTo(size.width * 0.85, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// 🧩 COMPONENTES REUTILIZABLES
class _GlassAppBar extends StatelessWidget {
  final WidgetRef ref;
  const _GlassAppBar({required this.ref});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: ClipPath(
          clipper: _GlassClipAppBar(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.15),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HISTORIAL DE MOVIMIENTOS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Auditoría de stock en tiempo real',
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () =>
                        ref.read(transactionsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassClipAppBar extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * 0.85, size.height * 0.85)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(child: Container(color: theme.scaffoldBackgroundColor)),
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassLoading extends StatelessWidget {
  const _GlassLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Colors.white70));
}

class _GlassError extends StatelessWidget {
  final String message;
  final WidgetRef ref;
  const _GlassError({required this.message, required this.ref});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: theme.colorScheme.error.withOpacity(0.8),
          ),
          const SizedBox(height: 12),
          Text(
            'Error de conexión',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(transactionsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
