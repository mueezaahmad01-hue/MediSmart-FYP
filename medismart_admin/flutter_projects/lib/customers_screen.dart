import 'package:flutter/material.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _customers = [
    {
      'name': 'Ahmed Khan',
      'email': 'ahmed@gmail.com',
      'phone': '0301-1234567',
      'address': 'Lahore, Pakistan',
    },
    {
      'name': 'Sara Ali',
      'email': 'sara@gmail.com',
      'phone': '0312-9876543',
      'address': 'Karachi, Pakistan',
    },
    {
      'name': 'Bilal Raza',
      'email': 'bilal@gmail.com',
      'phone': '0333-5556677',
      'address': 'Islamabad, Pakistan',
    },
    {
      'name': 'Fatima Noor',
      'email': 'fatima@gmail.com',
      'phone': '0345-1112233',
      'address': 'Peshawar, Pakistan',
    },
    {
      'name': 'Usman Tariq',
      'email': 'usman@gmail.com',
      'phone': '0321-4445566',
      'address': 'Multan, Pakistan',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
    c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          _hCell('Name', 2),
                          _hCell('Email', 3),
                          _hCell('Phone', 2),
                          _hCell('Address', 3),
                          _hCell('Actions', 2),
                        ],
                      ),
                    ),
                    // Rows
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                          child: Text('No customers found',
                              style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final c = _filtered[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xFFF0F0F0))),
                            ),
                            child: Row(
                              children: [
                                _rCell(c['name'], flex: 2, bold: true),
                                _rCell(c['email'], flex: 3),
                                _rCell(c['phone'], flex: 2),
                                _rCell(c['address'], flex: 3),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      _btn('View', Icons.visibility_rounded,
                                          const Color(0xFF1976D2),
                                              () => _showViewDialog(c)),
                                      const SizedBox(width: 6),
                                      _btn('Delete', Icons.delete_rounded,
                                          const Color(0xFFC62828),
                                              () => setState(() =>
                                              _customers.removeWhere(
                                                      (e) => e['email'] == c['email']))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hCell(String text, int flex) => Expanded(
    flex: flex,
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
  );

  Widget _rCell(String text, {int flex = 1, bool bold = false}) => Expanded(
    flex: flex,
    child: Text(text,
        style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF1A1A2E),
            fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
  );

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_rounded, color: Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(c['name'],
                style: const TextStyle(color: Color(0xFF1A1A2E))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dRow('Email', c['email']),
            _dRow('Phone', c['phone']),
            _dRow('Address', c['address']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00897B))),
          ),
        ],
      ),
    );
  }

  Widget _dRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value,
              style: const TextStyle(color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }
}