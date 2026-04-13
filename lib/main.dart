import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

// Internal Imports
import 'package:stockflow/core/services/api_services.dart';
import 'package:stockflow/view/ProfilePage.dart';
import 'package:stockflow/view/RetirosPage.dart';
import 'package:stockflow/view/SplashScreen.dart';


import 'core/providers/bloc/inventory_bloc.dart';

void main() {
  // Injecting the Bloc at the very top of the widget tree
  runApp(
    BlocProvider(
      create: (context) => InventoryBloc(ApiService())..add(FetchInventory()),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue.shade900,
      ),
      home: const SplashScreen(),
    );
  }
}

// --- NAVIGATION BINDER ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const InventaryPage(),
    const RetirosPage(),
    const ProfilePage()
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
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.remove_circle), label: 'Retiros'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
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

// --- 1. INVENTORY VIEW (Uses BlocBuilder) ---
class InventaryPage extends StatefulWidget {
  const InventaryPage({super.key});

  @override
  State<InventaryPage> createState() => _InventaryPageState();
}

class _InventaryPageState extends State<InventaryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with Search
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: Column(
            children: [
              const Text('INVENTARIO',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                      hintText: 'Buscar un producto...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search)),
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
                final filtered = state.products.where((p) =>
                    p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return RefreshIndicator(
                  onRefresh: () async => context.read<InventoryBloc>().add(FetchInventory()),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.75),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _ProductCard(item: item);
                    },
                  ),
                );
              } else if (state is InventoryError) {
                return Center(child: Text(state.message));
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: item['image_base64'] != null && item['image_base64'] != ""
                  ? ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.memory(base64Decode(item['image_base64']), fit: BoxFit.cover),
              )
                  : const Icon(Icons.inventory, size: 40, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? 'Producto',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  "Stock: ${item['quantity'] ?? 0}",
                  style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. ADD ITEM VIEW ---
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

  String? _selectedCategoryId;
  String? _selectedWarehouseId;
  List<dynamic> _categories = [];
  List<dynamic> _warehouses = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await Future.wait([_apiService.fetchCategories(), _apiService.fetchWarehouses()]);
      setState(() {
        _categories = res[0];
        _warehouses = res[1];
        if (_categories.isNotEmpty) _selectedCategoryId = _categories[0]['id'];
        if (_warehouses.isNotEmpty) _selectedWarehouseId = _warehouses[0]['id'];
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _skuController.text.isEmpty || _selectedCategoryId == null || _selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Llene todos los campos")));
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      "name": _nameController.text.trim(),
      "sku": _skuController.text.trim(),
      "quantity": int.tryParse(_quantityController.text) ?? 0,
      "category_id": _selectedCategoryId,
      "warehouse_id": _selectedWarehouseId,
      "image_base64": "",
    };

    bool success = await _apiService.addProduct(payload);

    if (mounted) setState(() => _isSaving = false);

    if (success) {
      // Automatic Refresh: Telling BLoC to fetch new products before closing
      context.read<InventoryBloc>().add(FetchInventory());
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Item")),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _inputField(_nameController, "Nombre del Producto", Icons.label),
            const SizedBox(height: 15),
            _inputField(_skuController, "SKU Único", Icons.qr_code),
            const SizedBox(height: 15),
            _inputField(_quantityController, "Cantidad Inicial", Icons.add_chart, isNum: true),
            const SizedBox(height: 25),
            _dropdown("Categoría", _selectedCategoryId, _categories, (v) => setState(() => _selectedCategoryId = v)),
            const SizedBox(height: 15),
            _dropdown("Almacén de Entrada", _selectedWarehouseId, _warehouses, (v) => setState(() => _selectedWarehouseId = v)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTRAR PRODUCTO"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController c, String l, IconData i, {bool isNum = false}) => TextField(
    controller: c,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: l, prefixIcon: Icon(i), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
  );

  Widget _dropdown(String l, String? v, List d, Function(String?) fn) => DropdownButtonFormField<String>(
    value: v,
    decoration: InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
    items: d.map((e) => DropdownMenuItem<String>(value: e['id'], child: Text(e['name']))).toList(),
    onChanged: fn,
  );
}