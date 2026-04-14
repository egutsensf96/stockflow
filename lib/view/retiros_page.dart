import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stockflow/core/services/api_services.dart';

class RetirosPage extends StatefulWidget {
  const RetirosPage({super.key});

  @override
  State<RetirosPage> createState() => _RetirosPageState();
}

class _RetirosPageState extends State<RetirosPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // ✅ Fetches StockTransaction records from /admin/tracker
      final data = await _apiService.fetchStockTransactions();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    // 1. Handle null or empty input
    if (dateStr == null || dateStr.isEmpty) return '--';

    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM, HH:mm').format(date);
    } catch (_) {
      // 2. Catch block MUST have a body (not arrow syntax)
      // 3. Return non-nullable String (dateStr is guaranteed non-null here)
      return dateStr;
    }
  }

  // Map transaction type to UI labels & colors
  ({String label, Color color, IconData icon}) _getTransactionMeta(
    String type,
  ) {
    switch (type.toUpperCase()) {
      case 'RECEIVE':
      case 'INITIAL':
        return (label: 'ENTRADA', color: Colors.green, icon: Icons.add_circle);
      case 'PICK':
      case 'DRAW':
        return (label: 'SALIDA', color: Colors.red, icon: Icons.remove_circle);
      case 'TRANSFER':
        return (
          label: 'TRASLADO',
          color: Colors.orange,
          icon: Icons.swap_horiz,
        );
      case 'ADJUST':
        return (label: 'AJUSTE', color: Colors.blue, icon: Icons.edit);
      default:
        return (label: type, color: Colors.grey, icon: Icons.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
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
                'MOVIMIENTOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Historial completo de inventario',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadTransactions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay movimientos registrados',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final txn = _transactions[index];
                      final product = txn['product'] ?? {};
                      final warehouse = txn['warehouse'] ?? {};
                      final user = txn['user'] ?? {};
                      final supplier = txn['supplier']; // Optional

                      final meta = _getTransactionMeta(txn['type']);
                      final change = txn['quantity_change'] ?? 0;
                      final isPositive = change >= 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(meta.icon, color: meta.color, size: 22),
                          ),
                          title: Text(
                            product['name'] ?? 'Producto',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📦 ${warehouse['name'] ?? 'Almacén'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (supplier != null && supplier['name'] != null)
                                Text(
                                  '🏭 ${supplier['name']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user['email'] ?? 'Sistema'} • ${_formatDate(txn['created_at'])}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}$change',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: meta.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: meta.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  meta.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: meta.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showTransactionDetails(context, txn),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _showTransactionDetails(BuildContext context, dynamic txn) {
    final product = txn['product'] ?? {};
    final warehouse = txn['warehouse'] ?? {};
    final user = txn['user'] ?? {};
    final supplier = txn['supplier'];
    final meta = _getTransactionMeta(txn['type']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalles del Movimiento',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // Details Grid
            _detailRow('Producto', product['name'] ?? 'N/A'),
            _detailRow('SKU', product['sku'] ?? 'N/A'),
            _detailRow('Almacén', warehouse['name'] ?? 'N/A'),
            _detailRow(
              'Cantidad',
              '${txn['quantity_change']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: meta.color,
                fontSize: 16,
              ),
            ),
            _detailRow('Tipo', meta.label),
            if (supplier != null && supplier['name'] != null)
              _detailRow('Proveedor', supplier['name']),
            _detailRow('Usuario', user['email'] ?? 'Sistema'),
            if (txn['notes']?.isNotEmpty == true)
              _detailRow('Notas', txn['notes']),
            _detailRow('Fecha', _formatDate(txn['created_at'])),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {TextStyle? style}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: style ?? const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
