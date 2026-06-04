import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/warehouses_provider.dart';

class WarehousesScreen extends ConsumerWidget {
  const WarehousesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _GlassAppBar(ref: ref),
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          ref
              .watch(warehousesProvider)
              .when(
                data: (items) => _WarehousesList(items: items, ref: ref),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white70),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '⚠️ $e',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: _GlowFAB(ref: ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// 📜 LISTA DE ALMACENES
class _WarehousesList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final WidgetRef ref;
  const _WarehousesList({required this.items, required this.ref});

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).padding.top + 15;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: headerHeight),
          child: Text(
            'No hay almacenes registrados',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            top: headerHeight,
            bottom: 100,
            left: 16,
            right: 16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _WarehouseCard(
                item: items[i],
                index: i,
                ref: ref,
              ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.1),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

// 🃏 TARJETA DE ALMACÉN
class _WarehouseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final WidgetRef ref;
  const _WarehouseCard({
    required this.item,
    required this.index,
    required this.ref,
  });

  void _showEditDialog(BuildContext parentContext) {
    _showWarehouseDialog(parentContext, ref, warehouse: item, isEdit: true);
  }

  void _confirmDelete(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(
          parentContext,
        ).colorScheme.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar almacén?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${item['name']}"? Si contiene productos con stock activo, el backend bloqueará la acción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(parentContext).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await ref
                    .read(warehousesProvider.notifier)
                    .delete(item['id'] as String);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Almacén eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('❌ $e'),
                      backgroundColor: Theme.of(
                        parentContext,
                      ).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipPath(
        clipper: _GlassClip(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.15),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item['location'] != null &&
                              (item['location'] as String).isNotEmpty)
                            Text(
                              '📍 ${item['location']}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: theme.colorScheme.primary,
                          onPressed: () => _showEditDialog(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined, size: 18),
                          color: theme.colorScheme.error,
                          onPressed: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ID: ${(item['id'] as String? ?? '').substring(0, 8)}...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🧩 DIÁLOGO REUTILIZABLE (Crear / Editar)
void _showWarehouseDialog(
  BuildContext parentContext,
  WidgetRef ref, {
  Map<String, dynamic>? warehouse,
  bool isEdit = false,
}) {
  final nameCtrl = TextEditingController(
    text: isEdit ? (warehouse?['name'] as String? ?? '') : '',
  );
  final locCtrl = TextEditingController(
    text: isEdit ? (warehouse?['location'] as String? ?? '') : '',
  );
  final theme = Theme.of(parentContext);
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: parentContext,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      title: Text(
        isEdit ? 'Editar Almacén' : 'Nuevo Almacén',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                ),
                validator: (v) =>
                    v == null || v.length < 2 ? 'Mínimo 2 caracteres' : null,
                autofocus: !isEdit,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              if (isEdit) {
                await ref
                    .read(warehousesProvider.notifier)
                    .updateWarehouse(
                      warehouse!['id'] as String,
                      name: nameCtrl.text,
                      location: locCtrl.text,
                    );
              } else {
                await ref
                    .read(warehousesProvider.notifier)
                    .create(name: nameCtrl.text, location: locCtrl.text);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? '✅ Almacén actualizado' : '✅ Almacén creado',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('❌ $e'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            }
          },
          child: Text(isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    ),
  );
}

class _GlassClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * 0.9)
    ..lineTo(size.width * 0.85, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _GlassAppBar extends StatelessWidget {
  final WidgetRef ref;
  const _GlassAppBar({required this.ref});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
        child: ClipPath(
          clipper: _GlassClip(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: t.colorScheme.surface.withOpacity(0.15),
                border: Border.all(
                  color: t.colorScheme.primary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ALMACENES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () =>
                        ref.read(warehousesProvider.notifier).refresh(),
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

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(child: Container(color: t.scaffoldBackgroundColor)),
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
                  t.colorScheme.secondary.withOpacity(0.15),
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
                  t.colorScheme.primary.withOpacity(0.1),
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

class _GlowFAB extends StatelessWidget {
  final WidgetRef ref;
  const _GlowFAB({required this.ref});
  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => _showWarehouseDialog(context, ref),
    label: const Text(
      'NUEVO ALMACÉN',
      style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w700),
    ),
    icon: const Icon(Icons.add_rounded),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  ).animate(target: 0).scaleXY(begin: 0.8, end: 1, curve: Curves.elasticOut);
}
