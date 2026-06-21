import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  String _filter = 'All';

  final CollectionReference prescriptionsRef = FirebaseFirestore.instance
      .collection('prescriptions');

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    if (_filter == 'All') return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      return status == _filter.toLowerCase();
    }).toList();
  }

  DateTime _getDate(Map<String, dynamic> data) {
    final value =
        data['createdAt'] ?? data['prescriptionDateTime'] ?? data['date'];

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return DateTime.now();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFE65100);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    await prescriptionsRef.doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _patientName(Map<String, dynamic> data) {
    return data['patientName']?.toString() ??
        data['userName']?.toString() ??
        data['userEmail']?.toString() ??
        'Unknown Patient';
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
                _filterBtn('All'),
                const SizedBox(width: 8),
                _filterBtn('Submitted'),
                const SizedBox(width: 8),
                _filterBtn('Approved'),
                const SizedBox(width: 8),
                _filterBtn('Rejected'),
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
                          _hCell('Presc. ID', 1),
                          _hCell('Patient', 2),
                          _hCell('Detected Medicines', 3),
                          _hCell('Date', 2),
                          _hCell('Status', 1),
                          _hCell('Actions', 3),
                        ],
                      ),
                    ),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            prescriptionsRef
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
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
                                'No prescriptions found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final data = doc.data() as Map<String, dynamic>;

                              final status =
                                  data['status']?.toString() ?? 'Submitted';

                              final detectedMedicines =
                                  (data['detectedMedicines']
                                              as List<dynamic>? ??
                                          [])
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
                                    _rCell(
                                      '#${doc.id.substring(0, 6).toUpperCase()}',
                                      flex: 1,
                                      bold: true,
                                      color: const Color(0xFF00897B),
                                    ),
                                    _rCell(_patientName(data), flex: 2),
                                    _rCell(
                                      detectedMedicines.isEmpty
                                          ? 'No medicine detected'
                                          : detectedMedicines,
                                      flex: 3,
                                    ),
                                    _rCell(
                                      _formatDate(_getDate(data)),
                                      flex: 2,
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusBg(status),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          _btn(
                                            'View',
                                            Icons.visibility_rounded,
                                            const Color(0xFF1976D2),
                                            () => _showViewDialog(doc.id, data),
                                          ),
                                          const SizedBox(width: 6),
                                          _btn(
                                            'Approve',
                                            Icons.check_rounded,
                                            const Color(0xFF2E7D32),
                                            () => _updateStatus(
                                              doc.id,
                                              'Approved',
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          _btn(
                                            'Reject',
                                            Icons.close_rounded,
                                            const Color(0xFFC62828),
                                            () => _updateStatus(
                                              doc.id,
                                              'Rejected',
                                            ),
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

  Widget _filterBtn(String label) {
    final isActive = _filter == label;

    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF00897B) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

  void _showViewDialog(String docId, Map<String, dynamic> p) {
    final detected = (p['detectedMedicines'] as List<dynamic>? ?? []).join(
      '\n',
    );

    final results = p['results'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.description_rounded, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Text(
                  '#${docId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(color: Color(0xFF1A1A2E)),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dRow('Patient', _patientName(p)),
                    _dRow('Email', p['userEmail']?.toString() ?? 'N/A'),
                    _dRow('Status', p['status']?.toString() ?? 'Submitted'),
                    _dRow('Date', _formatDate(_getDate(p))),
                    const SizedBox(height: 10),

                    const Text(
                      'Prescription Text:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['prescriptionText']?.toString() ?? 'N/A',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Detected Medicines:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detected.isEmpty ? 'No medicine detected' : detected,
                      style: const TextStyle(color: Color(0xFF00897B)),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'AI Results:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    if (results.isEmpty)
                      const Text(
                        'No AI results found',
                        style: TextStyle(color: Colors.grey),
                      ),

                    ...results.map((item) {
                      final r = item as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dRow(
                              'Original',
                              r['original']?.toString() ?? 'N/A',
                            ),
                            _dRow(
                              'Alternative',
                              r['alternative']?.toString() ?? 'Not Available',
                            ),
                            _dRow(
                              'Salt',
                              r['predictedSalt']?.toString() ?? 'N/A',
                            ),
                            _dRow('Confidence', '${r['confidence'] ?? 0}%'),
                            _dRow(
                              'AI Method',
                              r['aiMethod']?.toString() ?? 'N/A',
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFF00897B)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _dRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }
}
