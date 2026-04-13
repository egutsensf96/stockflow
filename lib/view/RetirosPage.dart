import 'package:flutter/material.dart';
import 'package:stockflow/core/services/api_services.dart';
import 'package:intl/intl.dart'; // Add to pubspec.yaml for date formatting

class RetirosPage extends StatefulWidget {
  const RetirosPage({super.key});

  @override
  State<RetirosPage> createState() => _RetirosPageState();
}

class _RetirosPageState extends State<RetirosPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _drawsFuture;

  @override
  void initState() {
    super.initState();
    _drawsFuture = _apiService.fetchDraws();
  }

  // Helper to format ISO date strings from Go
  String formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMM, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- HEADER ---
        Container(
          padding: const EdgeInsets.only(top: 60, bottom: 30),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
          child: const Column(
            children: [
              Text(
                'MOVIMIENTOS',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Historial de entradas y salidas',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        // --- DYNAMIC LIST ---
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _drawsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay movimientos registrados"));
              }

              final draws = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _drawsFuture = _apiService.fetchDraws();
                  });
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: draws.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                  itemBuilder: (context, index) {
                    final item = draws[index];

                    // 1. Get Product Name
                    final String productName = item['product']?['name'] ?? 'Producto';

                    // 2. Get User and Role (Nested JSON)
                    final String userName = item['retrieved_by']?['name'] ?? 'Admin';
                    final String userRole = item['retrieved_by']?['role']?['name'] ?? 'Encargado';

                    // 3. Movement Logic (Status-based)
                    // Logic: 'completed' means the product left the warehouse (OUT)
                    final bool isOut = item['status'] == 'completed';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isOut ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isOut ? Icons.arrow_outward : Icons.south_west, // Outward for OUT, SouthWest for IN
                            color: isOut ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatDate(item['created_at']), // Note: lowercase from Go JSON
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            // SHOWING NAME AND ROLE
                            Row(
                              children: [
                                const Icon(Icons.account_circle, size: 14, color: Colors.blueGrey),
                                const SizedBox(width: 4),
                                Text(
                                  "$userName ",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                Text(
                                  "($userRole)",
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // If you don't have a 'quantity' field in Draw model,
                            // we show "1" as a single movement count
                            Text(
                              '${isOut ? "-" : "+"}${item['quantity'] ?? 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isOut ? Colors.red : Colors.green,
                              ),
                            ),
                            Text(
                              isOut ? 'SALIDA' : 'ENTRADA',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isOut ? Colors.red : Colors.green
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}