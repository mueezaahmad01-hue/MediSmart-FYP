import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'medicines_screen.dart';
import 'alternatives_screen.dart';
import 'prescription_screen.dart';
import 'users_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selected = 0;

  // Live counts from Firestore
  int _totalOrders = 0;
  int _totalMedicines = 0;
  int _totalUsers = 0;
  int _totalPrescriptions = 0;
  double _totalRevenue = 0;
  bool _loadingStats = true;

  // Recent data
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _recentPrescriptions = [];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Orders'},
    {'icon': Icons.people_rounded, 'label': 'Customers'},
    {'icon': Icons.medication_rounded, 'label': 'Medicines'},
    {'icon': Icons.eco_rounded, 'label': 'Alternatives'},
    {'icon': Icons.description_rounded, 'label': 'Prescriptions'},
    {'icon': Icons.person_rounded, 'label': 'Users'},
  ];

  final List<String> _titles = [
    'Dashboard',
    'Orders',
    'Customers',
    'Medicines',
    'Alternatives',
    'Prescriptions',
    'Users',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _loadingStats = true);

    try {
      // Fetch all counts in parallel
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('orders').get(),
        FirebaseFirestore.instance.collection('medicines').get(),
        FirebaseFirestore.instance.collection('users').get(),
        FirebaseFirestore.instance.collection('prescriptions').get(),
        FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get(),
        FirebaseFirestore.instance
            .collection('prescriptions')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get(),
      ]);

      final ordersSnap = results[0];
      final medicinesSnap = results[1];
      final usersSnap = results[2];
      final prescriptionsSnap = results[3];
      final recentOrdersSnap = results[4];
      final recentPresSnap = results[5];

      // Calculate total revenue from orders
      double revenue = 0;
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final price =
            double.tryParse(
              data['totalAmount']?.toString() ??
                  data['price']?.toString() ??
                  data['total']?.toString() ??
                  '0',
            ) ??
            0;
        revenue += price;
      }

      setState(() {
        _totalOrders = ordersSnap.docs.length;
        _totalMedicines = medicinesSnap.docs.length;
        _totalUsers = usersSnap.docs.length;
        _totalPrescriptions = prescriptionsSnap.docs.length;
        _totalRevenue = revenue;
        _recentOrders =
            recentOrdersSnap.docs
                .map((d) => {'id': d.id, ...d.data()})
                .toList();
        _recentPrescriptions =
            recentPresSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _loadingStats = false;
      });
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      setState(() => _loadingStats = false);
    }
  }

  Widget _getScreen() {
    switch (_selected) {
      case 1:
        return const OrdersScreen();
      case 2:
        return const CustomersScreen();
      case 3:
        return const MedicinesScreen();
      case 4:
        return const AlternativesScreen();
      case 5:
        return const PrescriptionsScreen();
      case 6:
        return const UsersScreen();
      default:
        return _buildDashboardBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [_buildTopBar(), Expanded(child: _getScreen())],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            _titles[_selected],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          // Refresh button for dashboard
          if (_selected == 0)
            IconButton(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00897B)),
              tooltip: 'Refresh Dashboard',
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFF00897B),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF00897B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: Color(0xFF00897B),
                size: 28,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'MediSmart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Admin Panel',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, i) {
                final sel = _selected == i;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          sel
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: sel ? Border.all(color: Colors.white30) : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _menuItems[i]['icon'],
                          color: sel ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _menuItems[i]['label'],
                          style: TextStyle(
                            color: sel ? Colors.white : Colors.white70,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (sel) ...[
                          const Spacer(),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody() {
    if (_loadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00897B)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard(
                'Total Orders',
                '$_totalOrders',
                Icons.shopping_bag_rounded,
                const Color(0xFF00897B),
                const Color(0xFFE0F2F1),
                'Live from DB',
              ),
              const SizedBox(width: 16),
              _statCard(
                'Total Medicines',
                '$_totalMedicines',
                Icons.medication_rounded,
                const Color(0xFF1976D2),
                const Color(0xFFE3F2FD),
                'Live from DB',
              ),
              const SizedBox(width: 16),
              _statCard(
                'Total Users',
                '$_totalUsers',
                Icons.people_rounded,
                const Color(0xFF7B1FA2),
                const Color(0xFFF3E5F5),
                'Live from DB',
              ),
              const SizedBox(width: 16),
              _statCard(
                'Total Prescriptions',
                '$_totalPrescriptions',
                Icons.description_rounded,
                const Color(0xFF00838F),
                const Color(0xFFE0F7FA),
                'Live from DB',
              ),
              const SizedBox(width: 16),
              _statCard(
                'Revenue',
                'Rs.${_totalRevenue.toStringAsFixed(0)}',
                Icons.account_balance_wallet_rounded,
                const Color(0xFFE65100),
                const Color(0xFFFFF3E0),
                'Live from DB',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap any section to manage',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _menuCard(
                'Orders',
                Icons.shopping_bag_rounded,
                const Color(0xFF00897B),
                'View & manage all orders',
                1,
              ),
              const SizedBox(width: 16),
              _menuCard(
                'Customers',
                Icons.people_rounded,
                const Color(0xFF1976D2),
                'Registered app customers',
                2,
              ),
              const SizedBox(width: 16),
              _menuCard(
                'Medicines',
                Icons.medication_rounded,
                const Color(0xFF7B1FA2),
                'Add, edit & remove medicines',
                3,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _menuCard(
                'Alternatives',
                Icons.eco_rounded,
                const Color(0xFF2E7D32),
                'Manage alternative medicines',
                4,
              ),
              const SizedBox(width: 16),
              _menuCard(
                'Prescriptions',
                Icons.description_rounded,
                const Color(0xFFE65100),
                'Review uploaded prescriptions',
                5,
              ),
              const SizedBox(width: 16),
              _menuCard(
                'Users',
                Icons.person_rounded,
                const Color(0xFFC62828),
                'Manage user accounts',
                6,
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildRecentOrdersTable(),
          const SizedBox(height: 28),
          _buildRecentPrescriptionsTable(),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
    String trend,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    String label,
    IconData icon,
    Color color,
    String desc,
    int index,
  ) {
    return Expanded(
      child: _HoverCard(
        label: label,
        icon: icon,
        color: color,
        desc: desc,
        onTap: () => setState(() => _selected = index),
      ),
    );
  }

  // ── REAL DATA TABLES ──────────────────────────────────────────────────────

  Widget _buildRecentOrdersTable() {
    if (_recentOrders.isEmpty) {
      return _buildEmptyTable('Recent Orders', 'No orders yet');
    }

    final rows =
        _recentOrders.map((order) {
          final orderId =
              '#${order['id'].toString().substring(0, 6).toUpperCase()}';
          final customer =
              order['customerName']?.toString() ??
              order['userName']?.toString() ??
              order['userEmail']?.toString() ??
              'Unknown';
          final medicine =
              order['medicineName']?.toString() ??
              order['itemName']?.toString() ??
              order['medicine']?.toString() ??
              '-';
          final amount =
              order['totalAmount']?.toString() ??
              order['price']?.toString() ??
              order['total']?.toString() ??
              '0';
          final status = order['status']?.toString() ?? 'Pending';

          Color textColor;
          Color bgColor;
          switch (status.toLowerCase()) {
            case 'delivered':
              textColor = const Color(0xFF2E7D32);
              bgColor = const Color(0xFFE8F5E9);
              break;
            case 'cancelled':
              textColor = const Color(0xFFC62828);
              bgColor = const Color(0xFFFFEBEE);
              break;
            case 'processing':
              textColor = const Color(0xFF1976D2);
              bgColor = const Color(0xFFE3F2FD);
              break;
            default:
              textColor = const Color(0xFFE65100);
              bgColor = const Color(0xFFFFF3E0);
          }

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            children: [
              _tableCell(orderId, bold: true, color: const Color(0xFF00897B)),
              _tableCell(customer),
              _tableCell(medicine),
              _tableCell('Rs.$amount', bold: true),
              _statusCell(status, textColor, bgColor),
            ],
          );
        }).toList();

    return _buildTable(
      title: 'Recent Orders',
      headers: ['Order ID', 'Customer', 'Medicine', 'Amount', 'Status'],
      rows: rows,
      onViewAll: () => setState(() => _selected = 1),
    );
  }

  Widget _buildRecentPrescriptionsTable() {
    if (_recentPrescriptions.isEmpty) {
      return _buildEmptyTable('Recent Prescriptions', 'No prescriptions yet');
    }

    final rows =
        _recentPrescriptions.map((presc) {
          final prescId =
              '#PRE-${presc['id'].toString().substring(0, 4).toUpperCase()}';
          final patient =
              presc['userEmail']?.toString() ??
              presc['patientName']?.toString() ??
              'Unknown';
          final medicines =
              (presc['detectedMedicines'] as List<dynamic>?)
                  ?.take(1)
                  .join(', ') ??
              presc['medicineName']?.toString() ??
              '-';

          // Format date
          String date = '-';
          final ts = presc['prescriptionDateTime'] ?? presc['createdAt'];
          if (ts is Timestamp) {
            final d = ts.toDate();
            date =
                '${d.day.toString().padLeft(2, '0')}/'
                '${d.month.toString().padLeft(2, '0')}/${d.year}';
          }

          final status = presc['status']?.toString() ?? 'Pending';

          Color textColor;
          Color bgColor;
          switch (status.toLowerCase()) {
            case 'approved':
              textColor = const Color(0xFF2E7D32);
              bgColor = const Color(0xFFE8F5E9);
              break;
            case 'reviewed':
              textColor = const Color(0xFF1976D2);
              bgColor = const Color(0xFFE3F2FD);
              break;
            default:
              textColor = const Color(0xFFE65100);
              bgColor = const Color(0xFFFFF3E0);
          }

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            children: [
              _tableCell(prescId, bold: true, color: const Color(0xFF00897B)),
              _tableCell(patient),
              _tableCell(medicines),
              _tableCell(date),
              _statusCell(status, textColor, bgColor),
            ],
          );
        }).toList();

    return _buildTable(
      title: 'Recent Prescriptions',
      headers: ['Presc. ID', 'Patient', 'Medicine', 'Date', 'Status'],
      rows: rows,
      onViewAll: () => setState(() => _selected = 5),
    );
  }

  Widget _buildEmptyTable(String title, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(message, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildTable({
    required String title,
    required List<String> headers,
    required List<TableRow> rows,
    VoidCallback? onViewAll,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text(
                    'View All',
                    style: TextStyle(color: Color(0xFF00897B)),
                  ),
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {0: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
                children:
                    headers
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              ...rows,
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool bold = false,
    Color color = const Color(0xFF1A1A2E),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _statusCell(String status, Color textColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String desc;
  final VoidCallback onTap;

  const _HoverCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.desc,
    required this.onTap,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                _hovered ? widget.color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _hovered
                      ? widget.color.withValues(alpha: 0.4)
                      : Colors.transparent,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.desc,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
