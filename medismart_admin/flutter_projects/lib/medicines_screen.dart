import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final CollectionReference medicinesRef = FirebaseFirestore.instance
      .collection('medicines');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final category = data['category']?.toString().toLowerCase() ?? '';
      final salt = data['salt']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();

      return name.contains(q) || category.contains(q) || salt.contains(q);
    }).toList();
  }

  Future<void> _deleteMedicine(String docId) async {
    await medicinesRef.doc(docId).delete();
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
                      hintText: 'Search by name, salt or category...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF00897B),
                      ),
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
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showMedicineDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text(
                    'Add Medicine',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          _hCell('Image', 1),
                          _hCell('Medicine Name', 3),
                          _hCell('Salt', 2),
                          _hCell('Category', 2),
                          _hCell('Price', 1),
                          _hCell('Stock', 1),
                          _hCell('Alternatives', 2),
                          _hCell('Actions', 2),
                        ],
                      ),
                    ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: medicinesRef.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = _filterDocs(snapshot.data?.docs ?? []);

                          if (docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No medicines found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final data = doc.data() as Map<String, dynamic>;

                              final alternatives =
                                  (data['alternatives'] as List<dynamic>? ?? [])
                                      .join(', ');

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF0F0F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Image.asset(
                                        'assets/images/${data['image'] ?? ''}',
                                        height: 38,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const Icon(Icons.medication),
                                      ),
                                    ),
                                    _rCell(
                                      data['name']?.toString() ?? '',
                                      flex: 3,
                                      bold: true,
                                    ),
                                    _rCell(
                                      data['salt']?.toString() ?? '',
                                      flex: 2,
                                    ),
                                    _rCell(
                                      data['category']?.toString() ?? '',
                                      flex: 2,
                                    ),
                                    _rCell('Rs.${data['price'] ?? 0}', flex: 1),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        data['inStock'] == true
                                            ? 'In Stock'
                                            : 'Out',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              data['inStock'] == true
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _rCell(
                                      alternatives.isEmpty
                                          ? 'None'
                                          : alternatives,
                                      flex: 2,
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          _btn(
                                            'Edit',
                                            Icons.edit_rounded,
                                            const Color(0xFF1976D2),
                                            () => _showMedicineDialog(
                                              docId: doc.id,
                                              existingData: data,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _btn(
                                            'Delete',
                                            Icons.delete_rounded,
                                            const Color(0xFFC62828),
                                            () => _deleteMedicine(doc.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.grey,
      ),
    ),
  );

  Widget _rCell(
    String text, {
    int flex = 1,
    bool bold = false,
    Color color = const Color(0xFF1A1A2E),
  }) => Expanded(
    flex: flex,
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineDialog({
    String? docId,
    Map<String, dynamic>? existingData,
  }) {
    final isEdit = docId != null;

    final nameCtrl = TextEditingController(
      text: existingData?['name']?.toString() ?? '',
    );
    final saltCtrl = TextEditingController(
      text: existingData?['salt']?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(
      text: existingData?['category']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existingData?['price']?.toString() ?? '',
    );
    final imageCtrl = TextEditingController(
      text: existingData?['image']?.toString() ?? '',
    );
    final altCtrl = TextEditingController(
      text: (existingData?['alternatives'] as List<dynamic>? ?? []).join(', '),
    );

    bool inStock = existingData?['inStock'] == true;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  isEdit ? 'Edit Medicine' : 'Add Medicine',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field('Medicine Name', nameCtrl),
                        const SizedBox(height: 10),
                        _field('Salt', saltCtrl),
                        const SizedBox(height: 10),
                        _field('Category', categoryCtrl),
                        const SizedBox(height: 10),
                        _field('Price', priceCtrl),
                        const SizedBox(height: 10),
                        _field('Image file name e.g. panadol.png', imageCtrl),
                        const SizedBox(height: 10),
                        _field('Alternatives comma separated', altCtrl),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('In Stock'),
                          value: inStock,
                          activeColor: const Color(0xFF00897B),
                          onChanged: (value) {
                            setDialogState(() => inStock = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;

                      final alternatives =
                          altCtrl.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                      final medicineData = {
                        'name': nameCtrl.text.trim(),
                        'salt': saltCtrl.text.trim().toLowerCase(),
                        'category': categoryCtrl.text.trim(),
                        'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                        'image': imageCtrl.text.trim(),
                        'alternatives': alternatives,
                        'inStock': inStock,
                        'type': 'medicine',
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (isEdit) {
                        await medicinesRef.doc(docId).update(medicineData);
                      } else {
                        medicineData['createdAt'] =
                            FieldValue.serverTimestamp();
                        await medicinesRef.add(medicineData);
                      }

                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Save' : 'Add',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
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
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00897B)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
