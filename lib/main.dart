import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stockflow/core/providers/bloc/inventory_bloc.dart';
// Internal Imports
import 'package:stockflow/core/services/api_services.dart';
import 'package:stockflow/view/profile_page.dart';
import 'package:stockflow/view/retiros_page.dart';
import 'package:stockflow/view/splash_screen.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        // ✅ Inventory BLoC - Auto-fetches products on app start
        BlocProvider(
          create: (context) =>
              InventoryBloc(ApiService())..add(FetchInventory()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFlow ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue.shade900,
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- MAIN NAVIGATION (Bottom Bar) ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const InventaryPage(),
    const RetirosPage(), // ✅ Now shows StockTransaction audit trail
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: Colors.blue.shade900,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Movimientos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddItemPage()),
                );
              },
              backgroundColor: Colors.blue.shade900,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// --- INVENTORY PAGE (Uses BlocBuilder for auto-refresh) ---
class InventaryPage extends StatefulWidget {
  const InventaryPage({super.key});

  @override
  State<InventaryPage> createState() => _InventaryPageState();
}

class _InventaryPageState extends State<InventaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Search
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'INVENTARIO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar producto...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Reactive List using BLoC
        Expanded(
          child: BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InventoryLoaded) {
                final filtered = state.products
                    .where(
                      (p) => p['name'].toString().toLowerCase().contains(
                        _searchQuery,
                      ),
                    )
                    .toList();

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se encontró "$_searchQuery"',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<InventoryBloc>().add(FetchInventory()),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _ProductCard(item: item);
                    },
                  ),
                );
              } else if (state is InventoryError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error: ${state.message}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<InventoryBloc>().add(FetchInventory()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text("Sin datos"));
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic item;
  const _ProductCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: item['image_base64'] != null && item['image_base64'] != ""
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: Image.memory(
                        base64Decode(item['image_base64']),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.inventory, size: 40, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Producto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stock: ${item['quantity'] ?? 0}",
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (item['sku'] != null)
                  Text(
                    "SKU: ${item['sku']}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ADD ITEM PAGE (With auto-refresh on success) ---
class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController(text: "0");
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategoryId;
  String? _selectedWarehouseId;
  String? _selectedSupplierId;
  List<dynamic> _categories = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _suppliers = [];

  // 🆕 Image State
  File? _selectedImage;
  String? _imageBase64;
  bool _isImageLoading = false;

  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final res = await Future.wait([
        _apiService.fetchCategories(),
        _apiService.fetchWarehouses(),
        _apiService.fetchSuppliers(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = res[0];
        _warehouses = res[1];
        _suppliers = res[2];
        if (_categories.isNotEmpty) _selectedCategoryId = _categories[0]['id'];
        if (_warehouses.isNotEmpty) _selectedWarehouseId = _warehouses[0]['id'];
        _isLoadingData = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // 🆕 Pick & Convert Image to Base64
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80, // Compress to keep payload < 5MB
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isImageLoading = true;
      });

      final bytes = await _selectedImage!.readAsBytes();
      final base64String = base64Encode(bytes);

      if (mounted) {
        setState(() {
          _imageBase64 = base64String;
          _isImageLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImageLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar imagen: $e')));
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty ||
        _skuController.text.isEmpty ||
        _selectedCategoryId == null ||
        _selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete los campos obligatorios")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      "name": _nameController.text.trim(),
      "sku": _skuController.text.trim().toUpperCase(),
      "quantity": int.tryParse(_quantityController.text) ?? 0,
      "category_id": _selectedCategoryId,
      "warehouse_id": _selectedWarehouseId,
      "supplier_id": _selectedSupplierId,
      "image_base64": _imageBase64 ?? "", // 🆕 Send Base64 or empty string
    };

    try {
      await context.read<InventoryBloc>().addProductAndRefresh(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Producto registrado"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuevo Producto"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // 🆕 IMAGE PICKER WIDGET
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _isImageLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _selectedImage != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      _clearImage();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para agregar imagen',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _inputField(
                    _nameController,
                    "Nombre del Producto",
                    Icons.label,
                  ),
                  const SizedBox(height: 15),
                  _inputField(_skuController, "SKU Único", Icons.qr_code),
                  const SizedBox(height: 15),
                  _inputField(
                    _quantityController,
                    "Cantidad Inicial",
                    Icons.add_chart,
                    isNum: true,
                  ),
                  const SizedBox(height: 25),
                  _dropdown(
                    "Categoría",
                    _selectedCategoryId,
                    _categories,
                    (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: 15),
                  _dropdown(
                    "Almacén",
                    _selectedWarehouseId,
                    _warehouses,
                    (v) => setState(() => _selectedWarehouseId = v),
                  ),
                  if (_suppliers.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    _dropdown(
                      "Proveedor (Opcional)",
                      _selectedSupplierId,
                      _suppliers,
                      (v) => setState(() => _selectedSupplierId = v),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "REGISTRAR PRODUCTO",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _inputField(
    TextEditingController c,
    String label,
    IconData icon, {
    bool isNum = false,
  }) => TextField(
    controller: c,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade900),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<dynamic> items,
    Function(String?) onChanged,
  ) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    items: items
        .map(
          (e) => DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(e['name'].toString()),
          ),
        )
        .toList(),
    onChanged: onChanged,
    isExpanded: true,
  );
}
