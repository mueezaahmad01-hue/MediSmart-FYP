import 'package:flutter/material.dart';

class AlternativesScreen extends StatefulWidget {
  const AlternativesScreen({super.key});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _alternatives = [
    {
      'id': '#ALT-001',
      'original': 'Panadol',
      'originalId': '#MED-001',
      'alternative': 'Paracetamol',
      'category': 'Pain Relief',
      'price': 'Rs.30',
      'stock': '200',
      'expiry': '11/2027',
    },
    {
      'id': '#ALT-002',
      'original': 'Brufen',
      'originalId': '#MED-005',
      'alternative': 'Ibuprofen',
      'category': 'Pain Relief',
      'price': 'Rs.40',
      'stock': '150',
      'expiry': '06/2027',
    },
    {
      'id': '#ALT-003',
      'original': 'Augmentin',
      'originalId': '#MED-002',
      'alternative': 'Amoxicillin',
      'category': 'Antibiotic',
      'price': 'Rs.180',
      'stock': '90',
      'expiry': '03/2027',
    },
    {
      'id': '#ALT-004',
      'original': 'Nexium',
      'originalId': '#MED-006',
      'alternative': 'Omeprazole',
      'category': 'Gastro',
      'price': 'Rs.95',
      'stock': '110',
      'expiry': '08/2027',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _alternatives;
    return _alternatives
        .where((a) =>
    a['alternative'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a['original'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by alternative or original medicine...',
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF2E7D32)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('Add Alternative',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          _hCell('Alt ID', 1),
                          _hCell('Original Medicine', 2),
                          _hCell('Med ID', 1),
                          _hCell('Alternative', 2),
                          _hCell('Category', 2),
                          _hCell('Price', 1),
                          _hCell('Stock', 1),
                          _hCell('Expiry', 1),
                          _hCell('Actions', 2),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                          child: Text('No alternatives found',
                              style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final a = _filtered[i];
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
                                _rCell(a['id'],
                                    flex: 1,
                                    bold: true,
                                    color: const Color(0xFF2E7D32)),
                                _rCell(a['original'], flex: 2),
                                _rCell(a['originalId'],
                                    flex: 1,
                                    color: const Color(0xFF00897B)),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color(0xFF2E7D32),
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(a['alternative'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF2E7D32),
                                              fontWeight:
                                              FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                _rCell(a['category'], flex: 2),
                                _rCell(a['price'], flex: 1),
                                _rCell(a['stock'], flex: 1),
                                _rCell(a['expiry'], flex: 1),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      _btn('Edit', Icons.edit_rounded,
                                          const Color(0xFF1976D2),
                                              () => _showEditDialog(a)),
                                      const SizedBox(width: 6),
                                      _btn('Delete', Icons.delete_rounded,
                                          const Color(0xFFC62828),
                                              () => setState(() =>
                                              _alternatives.removeWhere(
                                                      (e) =>
                                                  e['id'] ==
                                                      a['id']))),
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
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey)),
  );

  Widget _rCell(String text,
      {int flex = 1,
        bool bold = false,
        Color color = const Color(0xFF1A1A2E)}) =>
      Expanded(
        flex: flex,
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: color,
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
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final originalCtrl = TextEditingController();
    final originalIdCtrl = TextEditingController();
    final altCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Alternative',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Original Medicine', originalCtrl),
              const SizedBox(height: 10),
              _field('Medicine ID (e.g. #MED-001)', originalIdCtrl),
              const SizedBox(height: 10),
              _field('Alternative Medicine', altCtrl),
              const SizedBox(height: 10),
              _field('Category', categoryCtrl),
              const SizedBox(height: 10),
              _field('Price (Rs.)', priceCtrl),
              const SizedBox(height: 10),
              _field('Stock', stockCtrl),
              const SizedBox(height: 10),
              _field('Expiry (MM/YYYY)', expiryCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (originalCtrl.text.isNotEmpty) {
                setState(() {
                  _alternatives.add({
                    'id': '#ALT-00${_alternatives.length + 1}',
                    'original': originalCtrl.text,
                    'originalId': originalIdCtrl.text,
                    'alternative': altCtrl.text,
                    'category': categoryCtrl.text,
                    'price': 'Rs.${priceCtrl.text}',
                    'stock': stockCtrl.text,
                    'expiry': expiryCtrl.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), elevation: 0),
            child: const Text('Add',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> a) {
    final originalCtrl = TextEditingController(text: a['original']);
    final originalIdCtrl = TextEditingController(text: a['originalId']);
    final altCtrl = TextEditingController(text: a['alternative']);
    final categoryCtrl = TextEditingController(text: a['category']);
    final priceCtrl = TextEditingController(
        text: a['price'].toString().replaceAll('Rs.', ''));
    final stockCtrl = TextEditingController(text: a['stock']);
    final expiryCtrl = TextEditingController(text: a['expiry']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Alternative',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Original Medicine', originalCtrl),
              const SizedBox(height: 10),
              _field('Medicine ID', originalIdCtrl),
              const SizedBox(height: 10),
              _field('Alternative Medicine', altCtrl),
              const SizedBox(height: 10),
              _field('Category', categoryCtrl),
              const SizedBox(height: 10),
              _field('Price (Rs.)', priceCtrl),
              const SizedBox(height: 10),
              _field('Stock', stockCtrl),
              const SizedBox(height: 10),
              _field('Expiry (MM/YYYY)', expiryCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final idx = _alternatives
                    .indexWhere((e) => e['id'] == a['id']);
                if (idx != -1) {
                  _alternatives[idx] = {
                    'id': a['id'],
                    'original': originalCtrl.text,
                    'originalId': originalIdCtrl.text,
                    'alternative': altCtrl.text,
                    'category': categoryCtrl.text,
                    'price': 'Rs.${priceCtrl.text}',
                    'stock': stockCtrl.text,
                    'expiry': expiryCtrl.text,
                  };
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), elevation: 0),
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2E7D32)),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}