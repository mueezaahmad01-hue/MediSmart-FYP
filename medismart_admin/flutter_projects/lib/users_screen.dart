import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _filter = 'All';

  final List<Map<String, dynamic>> _users = [
    {
      'name': 'Ahmed Khan',
      'email': 'ahmed@gmail.com',
      'role': 'Customer',
      'status': 'Active',
      'statusColor': const Color(0xFF2E7D32),
      'statusBg': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Sara Ali',
      'email': 'sara@gmail.com',
      'role': 'Customer',
      'status': 'Active',
      'statusColor': const Color(0xFF2E7D32),
      'statusBg': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Bilal Raza',
      'email': 'bilal@gmail.com',
      'role': 'Customer',
      'status': 'Blocked',
      'statusColor': const Color(0xFFC62828),
      'statusBg': const Color(0xFFFFEBEE),
    },
    {
      'name': 'Fatima Noor',
      'email': 'fatima@gmail.com',
      'role': 'Customer',
      'status': 'Active',
      'statusColor': const Color(0xFF2E7D32),
      'statusBg': const Color(0xFFE8F5E9),
    },
    {
      'name': 'Usman Tariq',
      'email': 'usman@gmail.com',
      'role': 'Customer',
      'status': 'Blocked',
      'statusColor': const Color(0xFFC62828),
      'statusBg': const Color(0xFFFFEBEE),
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _users;
    return _users.where((u) => u['status'] == _filter).toList();
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
                _filterBtn('Active'),
                const SizedBox(width: 8),
                _filterBtn('Blocked'),
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
                          _hCell('Name', 2),
                          _hCell('Email', 3),
                          _hCell('Role', 1),
                          _hCell('Status', 1),
                          _hCell('Actions', 3),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                          child: Text('No users found',
                              style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final u = _filtered[i];
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
                                _rCell(u['name'], flex: 2, bold: true),
                                _rCell(u['email'], flex: 3),
                                _rCell(u['role'], flex: 1),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: u['statusBg'],
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(u['status'],
                                        style: TextStyle(
                                            color: u['statusColor'],
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      _btn(
                                        u['status'] == 'Active'
                                            ? 'Block'
                                            : 'Unblock',
                                        u['status'] == 'Active'
                                            ? Icons.block_rounded
                                            : Icons.check_circle_rounded,
                                        u['status'] == 'Active'
                                            ? const Color(0xFFE65100)
                                            : const Color(0xFF2E7D32),
                                            () => _toggleStatus(u),
                                      ),
                                      const SizedBox(width: 6),
                                      _btn('Delete', Icons.delete_rounded,
                                          const Color(0xFFC62828),
                                              () => setState(() =>
                                              _users.removeWhere((e) =>
                                              e['email'] ==
                                                  u['email']))),
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

  void _toggleStatus(Map<String, dynamic> u) {
    setState(() {
      final idx = _users.indexWhere((e) => e['email'] == u['email']);
      if (idx != -1) {
        if (_users[idx]['status'] == 'Active') {
          _users[idx]['status'] = 'Blocked';
          _users[idx]['statusColor'] = const Color(0xFFC62828);
          _users[idx]['statusBg'] = const Color(0xFFFFEBEE);
        } else {
          _users[idx]['status'] = 'Active';
          _users[idx]['statusColor'] = const Color(0xFF2E7D32);
          _users[idx]['statusBg'] = const Color(0xFFE8F5E9);
        }
      }
    });
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
              color: isActive ? const Color(0xFF00897B) : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }

  Widget _hCell(String text, int flex) => Expanded(
    flex: flex,
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
  );

  Widget _rCell(String text,
      {int flex = 1, bool bold = false}) =>
      Expanded(
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
}
