import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockflow/providers/warehouses_provider.dart'; // ✅ Nuevo import para el filtro
import 'package:stockflow/screens/roles_screen.dart';
import 'package:stockflow/screens/suppliers_screen.dart';
import 'package:stockflow/screens/transactions_screen.dart';
import 'package:stockflow/screens/warehouses_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import 'add_product_sheet.dart';
import 'categories_screen.dart';
import 'edit_product_sheet.dart';
import 'login_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final inventory = ref.watch(inventoryProvider);

    if (auth == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _GlassAppBar(auth: auth, ref: ref),
      ),
      body: Stack(
        children: [
          const _AnimatedBackground(),
          inventory.when(
            // ✅ Pasamos auth y ref a la vista para el filtro admin
            data: (items) => _InventoryView(items: items, auth: auth, ref: ref),
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

// 📦 VISTA PRINCIPAL CON FILTRO ADMIN (Reemplaza _InventoryGrid)
class _InventoryView extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final AuthState auth;
  final WidgetRef ref;
  const _InventoryView({
    required this.items,
    required this.auth,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final headerHeight = MediaQuery.of(context).padding.top + 18;

    // ✅ Verificación de rol admin (case-insensitive)
    final isAdmin = auth.role.toLowerCase().contains('admin');

    return CustomScrollView(
      slivers: [
        // ✅ FILTRO SOLO PARA ADMIN: Se inserta dinámicamente
        if (auth.isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerHeight,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: _WarehouseFilterBar(ref: ref),
            ),
          ),

        SliverPadding(
          padding: EdgeInsets.only(
            // Ajustamos el top dinámicamente según la presencia del filtro
            top: isAdmin ? 12 : headerHeight,
            bottom: 100,
            left: 16,
            right: 16,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => Container(
                constraints: const BoxConstraints(maxHeight: 290),
                child: _ProductCard(item: items[i], index: i)
                    .animate(delay: (i * 70).ms)
                    .fadeIn()
                    .slideY(begin: 0.12, curve: Curves.easeOutCubic),
              ),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

// 🔍 BARRA DE FILTRO POR ALMACÉN (SOLO ADMIN)
// 🔍 BARRA DE FILTRO POR ALMACÉN (SOLO ADMIN) - ACTUALIZADA
class _WarehouseFilterBar extends ConsumerWidget {
  final WidgetRef ref;
  const _WarehouseFilterBar({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final whState = ref.watch(warehousesProvider);

    // ✅ Leer el ID del almacén seleccionado actualmente
    final selectedWarehouseId = ref
        .read(inventoryProvider.notifier)
        .activeWarehouseId;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.25),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Almacén:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: whState.when(
                  data: (whs) {
                    // Buscar el nombre del almacén seleccionado para mostrarlo (opcional, el dropdown ya lo hace automático)
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        // ✅ VINCULAR CON EL ESTADO ACTIVO DEL FILTRO
                        value: selectedWarehouseId,
                        hint: Text(
                          'Todos',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('📦 Todos los almacenes'),
                          ),
                          ...whs.map(
                            (w) => DropdownMenuItem(
                              value: w['id'] as String,
                              child: Text('🏢 ${w['name']}'),
                            ),
                          ),
                        ],
                        onChanged: (id) {
                          // ✅ Al cambiar, actualiza el estado y refresca el inventario
                          ref
                              .read(inventoryProvider.notifier)
                              .filterByWarehouse(id);
                        },
                        dropdownColor: theme.colorScheme.surface.withOpacity(
                          0.95,
                        ),
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  loading: () => Text(
                    'Cargando...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Error',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              // Botón para limpiar filtro rápidamente
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () => ref
                    .read(inventoryProvider.notifier)
                    .filterByWarehouse(null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 📱 MENÚ DE MÓDULOS (SHEET) - Sin cambios
void _showModulesSheet(BuildContext context) {
  final theme = Theme.of(context);
  final modules = [
    {
      'icon': Icons.people_outline,
      'label': 'Proveedores',
      'color': Colors.blueAccent,
    },
    {
      'icon': Icons.category_outlined,
      'label': 'Categorías',
      'color': Colors.purpleAccent,
    },
    {
      'icon': Icons.warehouse_outlined,
      'label': 'Almacenes',
      'color': Colors.orangeAccent,
    },
    {
      'icon': Icons.shield_outlined,
      'label': 'Roles',
      'color': Colors.tealAccent,
    },
    {
      'icon': Icons.history_outlined,
      'label': 'Historial',
      'color': Colors.cyanAccent,
    },
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.65,
        minChildSize: 0.4,
        builder: (_, controller) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.25),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'MÓDULOS DEL SISTEMA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: modules.map((m) {
                          return _ModuleTile(
                            icon: m['icon'] as IconData,
                            label: m['label'] as String,
                            color: m['color'] as Color,
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToModule(context, m['label'] as String);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _navigateToModule(BuildContext context, String label) {
  switch (label) {
    case 'Proveedores':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuppliersScreen()),
      );
      break;
    case 'Categorías':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
      break;
    case 'Almacenes':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WarehousesScreen()),
      );
      break;
    case 'Roles':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RolesScreen()),
      );
      break;
    case 'Historial':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
      );
      break;
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 🧊 APPBAR GLASS - Sin cambios mayores
class _GlassAppBar extends StatelessWidget {
  final AuthState auth;
  final WidgetRef ref;
  const _GlassAppBar({required this.auth, required this.ref});

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
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _GlassIcon(
                        icon: Icons.dashboard_rounded,
                        onTap: () => _showModulesSheet(context),
                        tooltip: 'Módulos',
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVENTARIO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                          Text(
                            'Tenant: ${auth.tenantId.toString().substring(0, 6)}•••',
                            style: TextStyle(
                              color: theme.colorScheme.primary.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _GlassIcon(
                        icon: Icons.refresh,
                        onTap: () =>
                            ref.read(inventoryProvider.notifier).refresh(),
                      ),
                      const SizedBox(width: 8),
                      _GlassIcon(
                        icon: Icons.logout,
                        onTap: () => ref.read(authProvider.notifier).logout(),
                        color: theme.colorScheme.error,
                      ),
                    ],
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

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String? tooltip;
  const _GlassIcon({
    required this.icon,
    required this.onTap,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color:
                color ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            size: 20,
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

// 🃏 TARJETA PRODUCTO - Sin cambios (ya optimizada)
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _ProductCard({required this.item, required this.index});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, c) => EditProductSheet(product: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageBase64 = item['image_base64'] as String?;
    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64);
      } catch (_) {}
    }
    final category = item['category'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Sin categoría';

    return InkWell(
      onTap: () => _openEdit(context),
      borderRadius: BorderRadius.circular(16),
      child: ClipPath(
        clipper: _DiagonalClip(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.18),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          size: 36,
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    item['name'] ?? 'Sin nombre',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'SKU: ${item['sku'] ?? '---'}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'x${item['quantity'] ?? 0}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Icon(
                        Icons.warehouse,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ],
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

class _DiagonalClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * 0.85)
    ..lineTo(size.width * 0.75, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ⏳ LOADING / ERROR / FAB / BACKGROUND - Sin cambios
class _GlassLoading extends StatelessWidget {
  const _GlassLoading();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.2),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white70,
                ),
                const SizedBox(height: 14),
                Text(
                  'Cargando inventario...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
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

class _GlassError extends StatelessWidget {
  final String message;
  final WidgetRef ref;
  const _GlassError({required this.message, required this.ref});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.2),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.4),
              ),
            ),
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
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(inventoryProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error.withOpacity(0.2),
                    foregroundColor: theme.colorScheme.error,
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

class _GlowFAB extends StatelessWidget {
  final WidgetRef ref;
  const _GlowFAB({required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              builder: (_, c) => const AddProductSheet(),
            ),
          ),
          label: const Text(
            'NUEVO',
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
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(child: Container(color: theme.scaffoldBackgroundColor)),
        _Blob(
          top: -80,
          left: -60,
          color: theme.colorScheme.secondary,
          opacity: 0.25,
          size: 220,
          duration: 5,
          offset: const Offset(20, 15),
        ),
        _Blob(
          bottom: -100,
          right: -80,
          color: theme.colorScheme.primary,
          opacity: 0.2,
          size: 260,
          duration: 7,
          offset: const Offset(-25, -20),
        ),
        _Blob(
          top: 0.4,
          left: 0.6,
          color: theme.colorScheme.primary,
          opacity: 0.12,
          size: 180,
          duration: 6,
          offset: const Offset(15, 25),
          useFractionalOffset: true,
        ),
      ],
    );
  }
}

class _Blob extends StatefulWidget {
  final double top, left, right, bottom, size, opacity, duration;
  final Color color;
  final Offset offset;
  final bool useFractionalOffset;
  const _Blob({
    this.top = 0,
    this.left = 0,
    this.right = 0,
    this.bottom = 0,
    required this.color,
    required this.opacity,
    required this.size,
    required this.duration,
    required this.offset,
    this.useFractionalOffset = false,
  });

  @override
  State<_Blob> createState() => _BlobState();
}

class _BlobState extends State<_Blob> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animX, _animY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration.toInt()),
    )..repeat(reverse: true);
    _animX = Tween<double>(
      begin: 0,
      end: widget.offset.dx,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _animY = Tween<double>(
      begin: 0,
      end: widget.offset.dy,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.useFractionalOffset ? null : widget.top,
      left: widget.useFractionalOffset ? null : widget.left,
      right: widget.right,
      bottom: widget.bottom,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(_animX.value, _animY.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(widget.opacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
