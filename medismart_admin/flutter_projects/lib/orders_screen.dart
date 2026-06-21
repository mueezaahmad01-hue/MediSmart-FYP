import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;

  final CollectionReference ordersRef = FirebaseFirestore.instance.collection(
    'orders',
  );

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime _getOrderDate(Map<String, dynamic> data) {
    final value = data['createdAt'] ?? data['orderDate'] ?? data['date'];

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return DateTime.now();
  }

  double _getTotal(Map<String, dynamic> data) {
    final value = data['total'] ?? data['totalAmount'] ?? data['amount'] ?? 0;

    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString().replaceAll('Rs.', '').trim()) ?? 0;
  }

  String _getCustomerName(Map<String, dynamic> data) {
    return data['customerName']?.toString() ??
        data['userName']?.toString() ??
        data['name']?.toString() ??
        data['userEmail']?.toString() ??
        'Unknown Customer';
  }

  List<dynamic> _getItems(Map<String, dynamic> data) {
    return data['items'] ??
        data['cartItems'] ??
        data['medicines'] ??
        data['products'] ??
        [];
  }

  List<QueryDocumentSnapshot> _filterOrders(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString() ?? 'Pending';
      final date = _getOrderDate(data);

      if (_fromDate != null && _toDate != null) {
        return date.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(_toDate!.add(const Duration(days: 1)));
      }

      if (_filter == 'Today') {
        return date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
      }

      if (_filter == 'This Week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(now.add(const Duration(days: 1)));
      }

      if (_filter == 'This Month') {
        return date.month == now.month && date.year == now.year;
      }

      if (_filter != 'All') {
        return status.toLowerCase() == _filter.toLowerCase();
      }

      return true;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'processing':
        return const Color(0xFF1976D2);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFE65100);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFE8F5E9);
      case 'processing':
        return const Color(0xFFE3F2FD);
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    await ordersRef.doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteOrder(String docId) async {
    await ordersRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot>(
          stream: ordersRef.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data?.docs ?? [];
            final filteredDocs = _filterOrders(allDocs);

            final deliveredCount =
                filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status']?.toString().toLowerCase() ==
                      'delivered';
                }).length;

            final pendingCount =
                filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status']?.toString().toLowerCase() == 'pending';
                }).length;

            final cancelledCount =
                filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString().toLowerCase();
                  return status == 'cancelled' || status == 'canceled';
                }).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterBtn('Today'),
                    _filterBtn('This Week'),
                    _filterBtn('This Month'),
                    _filterBtn('All'),
                    _datePicker(
                      label:
                          _fromDate == null
                              ? 'From Date'
                              : _formatDate(_fromDate!),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _fromDate = picked;
                            _filter = '';
                          });
                        }
                      },
                    ),
                    _datePicker(
                      label:
                          _toDate == null ? 'To Date' : _formatDate(_toDate!),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _toDate = picked;
                            _filter = '';
                          });
                        }
                      },
                    ),
                    if (_fromDate != null || _toDate != null)
                      _clearDateButton(),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _miniStat(
                      'Total Orders',
                      '${filteredDocs.length}',
                      Icons.shopping_bag_rounded,
                      const Color(0xFF00897B),
                    ),
                    const SizedBox(width: 12),
                    _miniStat(
                      'Delivered',
                      '$deliveredCount',
                      Icons.check_circle_rounded,
                      const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 12),
                    _miniStat(
                      'Pending',
                      '$pendingCount',
                      Icons.hourglass_empty_rounded,
                      const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 12),
                    _miniStat(
                      'Cancelled',
                      '$cancelledCount',
                      Icons.cancel_rounded,
                      const Color(0xFFC62828),
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
                            vertical: 14,
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
                              _headerCell('Order ID', 2),
                              _headerCell('Customer', 2),
                              _headerCell('Items', 2),
                              _headerCell('Total', 2),
                              _headerCell('Date', 2),
                              _headerCell('Status', 2),
                              _headerCell('Actions', 3),
                            ],
                          ),
                        ),

                        Expanded(
                          child:
                              filteredDocs.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No orders found',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, i) {
                                      final doc = filteredDocs[i];
                                      final data =
                                          doc.data() as Map<String, dynamic>;

                                      final items = _getItems(data);
                                      final itemCount = items.length;
                                      final status =
                                          data['status']?.toString() ??
                                          'Pending';
                                      final total = _getTotal(data);
                                      final orderDate = _getOrderDate(data);

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
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
                                            _rowCell(
                                              '#${doc.id.substring(0, 6).toUpperCase()}',
                                              flex: 2,
                                              bold: true,
                                              color: const Color(0xFF00897B),
                                            ),
                                            _rowCell(
                                              _getCustomerName(data),
                                              flex: 2,
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE0F2F1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$itemCount item${itemCount > 1 ? 's' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF00897B),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            _rowCell(
                                              'Rs.${total.toStringAsFixed(0)}',
                                              flex: 2,
                                              bold: true,
                                            ),
                                            _rowCell(
                                              _formatDate(orderDate),
                                              flex: 2,
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _statusBg(status),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  status,
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
                                                  _actionBtn(
                                                    'View',
                                                    Icons.visibility_rounded,
                                                    const Color(0xFF1976D2),
                                                    () => _showViewDialog(
                                                      doc.id,
                                                      data,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _actionBtn(
                                                    'Update',
                                                    Icons.edit_rounded,
                                                    const Color(0xFF00897B),
                                                    () => _showUpdateDialog(
                                                      doc.id,
                                                      data,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _actionBtn(
                                                    'Delete',
                                                    Icons.delete_rounded,
                                                    const Color(0xFFC62828),
                                                    () => _deleteOrder(doc.id),
                                                  ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _clearDateButton() {
    return GestureDetector(
      onTap:
          () => setState(() {
            _fromDate = null;
            _toDate = null;
            _filter = 'All';
          }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC62828).withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear_rounded, color: Color(0xFFC62828), size: 14),
            SizedBox(width: 4),
            Text(
              'Clear',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
      onTap:
          () => setState(() {
            _filter = label;
            _fromDate = null;
            _toDate = null;
          }),
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

  Widget _datePicker({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF00897B),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, int flex) => Expanded(
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

  Widget _rowCell(
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

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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

  void _showViewDialog(String docId, Map<String, dynamic> order) {
    final items = _getItems(order);
    final total = _getTotal(order);
    final status = order['status']?.toString() ?? 'Pending';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.shopping_bag_rounded,
                  color: Color(0xFF00897B),
                ),
                const SizedBox(width: 8),
                Text(
                  '#${docId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(color: Color(0xFF00897B)),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogRow('Customer', _getCustomerName(order)),
                    _dialogRow('Date', _formatDate(_getOrderDate(order))),
                    _dialogRow('Status', status),
                    _dialogRow(
                      'Address',
                      order['address']?.toString() ?? 'N/A',
                    ),
                    _dialogRow(
                      'Payment',
                      order['paymentMethod']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Order Items:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Medicine',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'Qty',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...items.map((item) {
                            final itemMap = item as Map<String, dynamic>;
                            final name =
                                itemMap['name']?.toString() ??
                                itemMap['medicineName']?.toString() ??
                                itemMap['medicine']?['name']?.toString() ??
                                'Medicine';

                            final qty =
                                int.tryParse(
                                  (itemMap['quantity'] ?? itemMap['qty'] ?? 1)
                                      .toString(),
                                ) ??
                                1;

                            final price =
                                double.tryParse(
                                  (itemMap['price'] ??
                                          itemMap['medicine']?['price'] ??
                                          0)
                                      .toString(),
                                ) ??
                                0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '× $qty',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs.${(price * qty).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 4,
                                  child: Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                                const Expanded(flex: 1, child: SizedBox()),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Rs.${total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00897B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  void _showUpdateDialog(String docId, Map<String, dynamic> order) {
    String selectedStatus = order['status']?.toString() ?? 'Pending';
    final statuses = ['Pending', 'Processing', 'Delivered', 'Cancelled'];

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Update Order Status',
                    style: TextStyle(color: Color(0xFF1A1A2E)),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        statuses.map((s) {
                          return RadioListTile<String>(
                            value: s,
                            groupValue: selectedStatus,
                            activeColor: const Color(0xFF00897B),
                            title: Text(s),
                            onChanged: (v) {
                              if (v == null) return;
                              setDialogState(() => selectedStatus = v);
                            },
                          );
                        }).toList(),
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
                        await _updateStatus(docId, selectedStatus);
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
