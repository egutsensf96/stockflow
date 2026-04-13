import 'package:flutter/material.dart';
class RetirosPage extends StatelessWidget {
  const RetirosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the transactions
    final List<Map<String, dynamic>> transactions = [
      {'name': 'Martillo de Acero', 'qty': 5, 'type': 'IN', 'date': '12 Oct, 2023'},
      {'name': 'Pintura Blanca 1L', 'qty': 2, 'type': 'OUT', 'date': '11 Oct, 2023'},
      {'name': 'Clavos 2 pulgadas', 'qty': 50, 'type': 'IN', 'date': '10 Oct, 2023'},
      {'name': 'Taladro Percutor', 'qty': 1, 'type': 'OUT', 'date': '09 Oct, 2023'},
      {'name': 'Cinta Métrica 5m', 'qty': 10, 'type': 'IN', 'date': '08 Oct, 2023'},
    ];

    return Column(
      children: [
        // Consistent Header
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
                'RETIROS Y ENTRADAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Historial de movimientos',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        // Transaction List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final item = transactions[index];
              final bool isOut = item['type'] == 'OUT';

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
                      isOut ? Icons.arrow_outward : Icons.south_west,
                      color: isOut ? Colors.red : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(
                    item['date'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isOut ? "-" : "+"}${item['qty']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOut ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        isOut ? 'Salida' : 'Entrada',
                        style: const TextStyle(fontSize: 10, color: Colors.black38),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}