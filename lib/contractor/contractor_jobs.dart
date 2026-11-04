import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../firestore_helper.dart';
import '../ai_service.dart';
import '../image_service.dart';
import '../login_screen.dart';

class ContractorJobs extends StatefulWidget {
  const ContractorJobs({super.key});
  @override
  State<ContractorJobs> createState() => _ContractorJobsState();
}

class _ContractorJobsState extends State<ContractorJobs> {
  Future<void> _complete(String docId, Map<String, dynamic> t) async {
    final proof =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (proof == null) return;

    final compressed = await ImageService.compressForUpload(File(proof.path));
    final ok = await AIService.verifyFix(t['photoPath'], compressed.path);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI could not verify fix. Upload clearer photo.')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await FirestoreHelper.updateTicket(
        docId, {'status': 'completed', 'proofPath': compressed.path});
    messenger.showSnackBar(const SnackBar(
        content: Text('✅ Job completed! Citizen notified.')));
  }

  void _showDetail(String docId, Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                      (t['lat'] as num?)?.toDouble() ?? 24.8607,
                      (t['lng'] as num?)?.toDouble() ?? 67.0011),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.demo.saafsarak',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(
                          (t['lat'] as num?)?.toDouble() ?? 24.8607,
                          (t['lng'] as num?)?.toDouble() ?? 67.0011),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 40),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${t['type']} — Severity ${t['severity']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Mark Complete + Upload Proof'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _complete(docId, t);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contractor Jobs'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.ticketsStream(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final jobs = docs
              .where((d) => (d.data() as Map)['status'] == 'approved')
              .toList();

          if (jobs.isEmpty) {
            return const Center(child: Text('No jobs assigned yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (_, i) {
              final doc = jobs[i];
              final t = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showDetail(doc.id, t),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: t['photoPath'] != null &&
                                  File(t['photoPath']).existsSync()
                              ? Image.file(File(t['photoPath']),
                                  width: 70, height: 70, fit: BoxFit.cover)
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[300]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['type'] ?? 'Issue',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 6),
                              Text('Severity ${t['severity']}/10',
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              Text(
                                  '📍 ${((t['lat'] as num?) ?? 0).toStringAsFixed(3)}, ${((t['lng'] as num?) ?? 0).toStringAsFixed(3)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}