import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/dropdown_providers.dart';
import '../providers/inventory_provider.dart';

class AddProductSheet extends ConsumerStatefulWidget {
  const AddProductSheet({super.key});
  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  String? _categoryId, _supplierId, _warehouseId;
  File? _photo;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _photo = File(picked.path);
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error al cargar imagen: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔴 Validación estricta: Warehouse es requerido por tu backend Go
    if (_categoryId == null || _warehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona Categoría y Almacén'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final imageBase64 = _imageBytes != null
          ? base64Encode(_imageBytes!)
          : null;

      await ref
          .read(inventoryProvider.notifier)
          .addProduct(
            name: _nameCtrl.text.trim(),
            sku: _skuCtrl.text.trim().toUpperCase(),
            quantity: int.parse(_qtyCtrl.text),
            categoryId: _categoryId!,
            warehouseId: _warehouseId!,
            supplierId: _supplierId, // Opcional según backend
            imageBase64: imageBase64,
          );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Producto creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NUEVO PRODUCTO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 📝 SECCIÓN: DATOS BÁSICOS
                const Text(
                  'Información Básica',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _GlassFormField(
                  controller: _nameCtrl,
                  label: 'Nombre del producto',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      v == null || v.length < 3 ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 12),
                _GlassFormField(
                  controller: _skuCtrl,
                  label: 'SKU (Código único)',
                  icon: Icons.qr_code,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                _GlassFormField(
                  controller: _qtyCtrl,
                  label: 'Cantidad inicial',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || int.tryParse(v) == null || int.parse(v) < 0
                      ? 'Número válido ≥ 0'
                      : null,
                ),

                const SizedBox(height: 20),

                // 🏷️ SECCIÓN: CLASIFICACIÓN
                const Text(
                  'Clasificación',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                _SectionRow(
                  title: 'Categoría',
                  child: ref
                      .watch(categoriesProvider)
                      .when(
                        data: (cats) => _GlassDropdown(
                          value: _categoryId,
                          items: cats
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(c['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                          hint: 'Selecciona...',
                        ),
                        loading: () => const _GlassDropdown(
                          value: null,
                          items: [],
                          onChanged: null,
                          hint: 'Cargando...',
                        ),
                        error: (_, __) => _GlassDropdown(
                          value: null,
                          items: [],
                          onChanged: null,
                          hint: 'Error',
                          isError: true,
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                _SectionRow(
                  title: 'Proveedor',
                  child: ref
                      .watch(suppliersProvider)
                      .when(
                        data: (sups) => _GlassDropdown(
                          value: _supplierId,
                          items: sups
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s['id'] as String,
                                  child: Text(s['name'] as String),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _supplierId = v),
                          hint: 'Seleccionar proveedor (Opcional)',
                        ),
                        loading: () => const _GlassDropdown(
                          value: null,
                          items: [],
                          onChanged: null,
                          hint: 'Cargando...',
                        ),
                        error: (_, __) => _GlassDropdown(
                          value: null,
                          items: [],
                          onChanged: null,
                          hint: 'Error',
                          isError: true,
                        ),
                      ),
                ),

                const SizedBox(height: 20),

                // 🏭 SECCIÓN: LOGÍSTICA (Requerido por backend)
                const Text(
                  'Almacén Inicial',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ref
                    .watch(warehousesProvider)
                    .when(
                      data: (whs) => _GlassDropdown(
                        value: _warehouseId,
                        items: whs
                            .map(
                              (w) => DropdownMenuItem(
                                value: w['id'] as String,
                                child: Text(w['name'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _warehouseId = v),
                        hint: 'Almacén donde se registrará stock',
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      loading: () => const _GlassDropdown(
                        value: null,
                        items: [],
                        onChanged: null,
                        hint: 'Cargando...',
                      ),
                      error: (_, __) => _GlassDropdown(
                        value: null,
                        items: [],
                        onChanged: null,
                        hint: 'Error',
                        isError: true,
                      ),
                    ),

                const SizedBox(height: 24),

                // 📸 SECCIÓN: IMAGEN
                const Text(
                  'Imagen del producto',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassImageButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Cámara',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 16),
                    _GlassImageButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galería',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
                if (_photo != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.memory(
                          _imageBytes!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () => setState(() {
                              _photo = null;
                              _imageBytes = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ✅ BOTÓN GUARDAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isSubmitting ? 0 : 12,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black54,
                            ),
                          )
                        : const Text(
                            'GUARDAR PRODUCTO',
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🧩 COMPONENTES REUTILIZABLES DEL UI

class _SectionRow extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionRow({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GlassFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  const _GlassFormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(letterSpacing: 0.3),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary.withOpacity(0.85),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}

class _GlassDropdown extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final String hint;
  final bool isError;
  final String? Function(String?)? validator;
  const _GlassDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.isError = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isError
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.35),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dropdownColor: theme.colorScheme.surface.withOpacity(0.95),
      style: TextStyle(
        color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
      ),
      hint: Text(
        hint,
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
      ),
      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
      validator: validator,
    );
  }
}

class _GlassImageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassImageButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
