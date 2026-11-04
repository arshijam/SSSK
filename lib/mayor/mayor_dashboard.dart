import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../firestore_helper.dart';
import '../auth_service.dart';
import '../login_screen.dart';

class MayorDashboard extends StatefulWidget {
  const MayorDashboard({super.key});
  @override
  State<MayorDashboard> createState() => _MayorDashboardState();
}

class _MayorDashboardState extends State<MayorDashboard> {
  List<Map<String, dynamic>> _contractors = [];
  List<Map<String, dynamic>> _pendingContractors = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await FirestoreHelper.getUsers();
    if (!mounted) return;
    setState(() {
      _contractors = users
          .where((u) => u['role'] == 'contractor' && u['isApproved'] == 1)
          .toList();
      _pendingContractors = users
          .where((u) => u['role'] == 'contractor' && u['isApproved'] == 0)
          .toList();
    });
  }

  Future<void> _approveContractor(String docId) async {
    await AuthService.approveContractor(docId);
    await _loadUsers();
  }

  Future<void> _rejectContractor(String docId) async {
    await AuthService.rejectContractor(docId);
    await _loadUsers();
  }

  Future<void> _approve(
      String docId, Map<String, dynamic> t, String name) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await FirestoreHelper.updateTicket(docId, {
      'status': 'approved',
      'contractor': name,
      'verified': 'real',
    });
    nav.pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('✅ Assigned to contractor')));
  }

  Future<void> _reject(String docId) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    await FirestoreHelper.updateTicket(
        docId, {'status': 'rejected', 'verified': 'fake'});
    nav.pop();
    messenger.showSnackBar(
        const SnackBar(content: Text('❌ Marked as fake')));
  }

  void _openVerifyModal(String docId, Map<String, dynamic> t) {
    String? selected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verify Report',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (t['photoPath'] != null &&
                  File(t['photoPath']).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(t['photoPath']),
                      height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(t['type'] ?? ''),
              Text('Severity ${t['severity']}/10'),
              const SizedBox(height: 20),
              const Text('Assign contractor',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Contractor',
                    border: OutlineInputBorder()),
                items: _contractors
                    .map((c) => DropdownMenuItem(
                        value: c['name'] as String,
                        child: Text(c['name'])))
                    .toList(),
                onChanged: (v) => setModal(() => selected = v),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Real'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    onPressed: selected == null
                        ? null
                        : () => _approve(docId, t, selected!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Fake'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    onPressed: () => _reject(docId),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: c, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _ticketCard(String docId, Map<String, dynamic> t) {
    final sev = (t['severity'] ?? 0) as int;
    final status = t['status'] ?? 'pending';
    final c = status == 'completed'
        ? Colors.green
        : status == 'approved'
            ? Colors.orange
            : status == 'rejected'
                ? Colors.purple
                : Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: t['photoPath'] != null &&
                      File(t['photoPath']).existsSync()
                  ? Image.file(File(t['photoPath']),
                      width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['type'] ?? 'Issue',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Sev $sev',
                        style: TextStyle(
                            color: sev >= 8 ? Colors.red : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text(status,
                        style: TextStyle(
                            color: c,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
            if (status == 'pending')
              ElevatedButton(
                onPressed: () => _openVerifyModal(docId, t),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white),
                child: const Text('Verify'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.ticketsStream(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final tickets = docs
              .map((d) =>
                  {...d.data() as Map<String, dynamic>, 'docId': d.id})
              .toList();

          final pending =
              tickets.where((t) => t['status'] == 'pending').toList();
          final approved =
              tickets.where((t) => t['status'] == 'approved').toList();
          final completed =
              tickets.where((t) => t['status'] == 'completed').toList();
          final critical = tickets
              .where((t) => (t['severity'] ?? 0) as int >= 8)
              .length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mayor Command Center',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.white),
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      _statCard('Total', '${tickets.length}', Colors.white),
                      _statCard('Critical', '$critical', Colors.redAccent),
                      _statCard('Pending', '${pending.length}', Colors.amber),
                      _statCard('Fixed', '${completed.length}',
                          Colors.greenAccent),
                    ]),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(24.8607, 67.0011),
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.demo.saafsarak',
                    ),
                    MarkerLayer(
                      markers: tickets.map((t) {
                        final sev = (t['severity'] ?? 0) as int;
                        final s = t['status'] ?? 'pending';
                        final c = s == 'completed'
                            ? Colors.green
                            : s == 'rejected'
                                ? Colors.purple
                                : sev >= 8
                                    ? Colors.red
                                    : Colors.orange;
                        return Marker(
                          point: LatLng(
                              (t['lat'] as num?)?.toDouble() ?? 24.8607,
                              (t['lng'] as num?)?.toDouble() ?? 67.0011),
                          width: 36,
                          height: 36,
                          child: Icon(Icons.location_pin,
                              color: c, size: 36),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_pendingContractors.isNotEmpty) ...[
                      const Text('CONTRACTOR APPROVALS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      ..._pendingContractors.map((c) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(c['name'] ?? ''),
                              subtitle: Text(c['phone'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () => _approveContractor(
                                        c['docId'] as String),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () => _rejectContractor(
                                        c['docId'] as String),
                                  ),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 8),
                    ],
                    const Text('PENDING VERIFICATION',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    ...pending.map(
                        (t) => _ticketCard(t['docId'] as String, t)),
                    const SizedBox(height: 8),
                    const Text('IN PROGRESS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    ...approved.map(
                        (t) => _ticketCard(t['docId'] as String, t)),
                    const SizedBox(height: 8),
                    const Text('COMPLETED',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    ...completed.map(
                        (t) => _ticketCard(t['docId'] as String, t)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}