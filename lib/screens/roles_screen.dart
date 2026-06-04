import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/roles_provider.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rolesState = ref.watch(rolesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _GlassAppBar(ref: ref),
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          rolesState.when(
            data: (roles) => _RolesList(roles: roles, ref: ref),
            loading: () => const _GlassLoading(),
            error: (err, _) => _GlassError(message: '$err', ref: ref),
          ),
        ],
      ),
      floatingActionButton: _GlowFAB(ref: ref),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// 📜 LISTA DE ROLES
class _RolesList extends StatelessWidget {
  final List<Map<String, dynamic>> roles;
  final WidgetRef ref;
  const _RolesList({required this.roles, required this.ref});

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).padding.top + 10;

    if (roles.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: headerHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay roles creados',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el botón + para crear el primero',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
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
              (_, i) => _RoleCard(
                role: roles[i],
                index: i,
                ref: ref,
              ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.1),
              childCount: roles.length,
            ),
          ),
        ),
      ],
    );
  }
}

// 🃏 TARJETA DE ROL
class _RoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final int index;
  final WidgetRef ref;
  const _RoleCard({required this.role, required this.index, required this.ref});

  // ✅ CORREGIDO: Usa parentContext para ScaffoldMessenger y dialogContext para Navigator.pop
  void _showEditDialog(BuildContext parentContext) {
    final nameCtrl = TextEditingController(text: role['name'] as String? ?? '');
    final descCtrl = TextEditingController(
      text: role['description'] as String? ?? '',
    );
    final theme = Theme.of(parentContext);

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        title: const Text(
          'Editar Rol',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del rol',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    v == null || v.length < 3 ? 'Mínimo 3 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().length < 3) return;
              try {
                await ref
                    .read(rolesProvider.notifier)
                    .updateRole(
                      id: role['id'] as String,
                      name: nameCtrl.text,
                      description: descCtrl.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                  ); // ✅ Cierra con su propio contexto
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Rol actualizado'),
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ✅ CORREGIDO: Misma lógica para eliminación
  void _confirmDelete(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(
          parentContext,
        ).colorScheme.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar rol?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar "${role['name']}"? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Theme.of(
              parentContext,
            ).colorScheme.onSurface.withOpacity(0.8),
          ),
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
                    .read(rolesProvider.notifier)
                    .deleteRole(role['id'] as String);
                if (dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                  ); // ✅ Cierra con su propio contexto
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Rol eliminado'),
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
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = role['name'] as String? ?? 'Sin nombre';
    final description = role['description'] as String? ?? 'Sin descripción';
    final isGlobal = role['is_global'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipPath(
        clipper: _GlassClipRole(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.15),
              border: Border.all(
                color: isGlobal
                    ? theme.colorScheme.secondary.withOpacity(0.4)
                    : theme.colorScheme.primary.withOpacity(0.25),
                width: 1.2,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (isGlobal
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isGlobal
                                  ? Icons.admin_panel_settings
                                  : Icons.shield_outlined,
                              color: isGlobal
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (isGlobal)
                                  Text(
                                    '• Rol global del sistema',
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: isGlobal
                              ? null
                              : () => _showEditDialog(
                                  context,
                                ), // ✅ Pasa context como parentContext
                          tooltip: isGlobal
                              ? 'Rol global: no editable'
                              : 'Editar',
                          color: isGlobal
                              ? Colors.grey
                              : theme.colorScheme.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outlined, size: 18),
                          onPressed: isGlobal
                              ? null
                              : () => _confirmDelete(
                                  context,
                                ), // ✅ Pasa context como parentContext
                          tooltip: isGlobal
                              ? 'Rol global: no eliminable'
                              : 'Eliminar',
                          color: isGlobal
                              ? Colors.grey
                              : theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ID: ${(role['id'] as String? ?? '').substring(0, 8)}...',
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

class _GlassClipRole extends CustomClipper<Path> {
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
                        'GESTIÓN DE ROLES',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Control de permisos por tenant',
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => ref.read(rolesProvider.notifier).refresh(),
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
            onPressed: () => ref.read(rolesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _GlowFAB extends StatelessWidget {
  final WidgetRef ref;
  const _GlowFAB({required this.ref});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context, ref),
          label: const Text(
            'NUEVO ROL',
            style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        )
        .animate(target: 0)
        .scaleXY(begin: 0.8, end: 1, curve: Curves.elasticOut)
        .then()
        .shimmer(
          duration: 1.5.seconds,
          color: theme.colorScheme.primary.withOpacity(0.4),
        );
  }

  void _showCreateDialog(BuildContext parentContext, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
        title: const Text(
          'Nuevo Rol',
          style: TextStyle(fontWeight: FontWeight.w700),
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
                    labelText: 'Nombre del rol *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.length < 3 ? 'Mínimo 3 caracteres' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 3,
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
                await ref
                    .read(rolesProvider.notifier)
                    .createRole(
                      name: nameCtrl.text,
                      description: descCtrl.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Rol creado'),
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
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
