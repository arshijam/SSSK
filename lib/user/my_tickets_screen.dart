import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firestore_helper.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  Color _c(String s) => s == 'completed'
      ? Colors.green
      : s == 'approved'
          ? Colors.orange
          : s == 'rejected'
              ? Colors.red
              : Colors.blueGrey;

  IconData _icon(String s) => s == 'completed'
      ? Icons.check_circle
      : s == 'approved'
          ? Icons.build
          : s == 'rejected'
              ? Icons.cancel
              : Icons.hourglass_empty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reported Issues'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.ticketsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
                child: Text('No tickets yet',
                    style: TextStyle(color: Colors.grey[600])));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final t = docs[i].data() as Map<String, dynamic>;
              final status = t['status'] as String? ?? 'pending';
              final c = _c(status);
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: t['photoPath'] != null &&
                                    File(t['photoPath']).existsSync()
                                ? Image.file(File(t['photoPath']),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover)
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    child:
                                        const Icon(Icons.image, size: 30)),
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
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: c.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(children: [
                                      Icon(_icon(status),
                                          size: 14, color: c),
                                      const SizedBox(width: 4),
                                      Text(status,
                                          style: TextStyle(
                                              color: c,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ]),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Sev ${t['severity']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (status == 'completed') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Your problem has been solved!',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold))),
                          ]),
                        ),
                        if (t['proofPath'] != null &&
                            File(t['proofPath']).existsSync()) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(File(t['proofPath']),
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        ],
                      ],
                      if (status == 'rejected') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(children: [
                            Icon(Icons.info, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Report was reviewed and marked invalid.',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))),
                          ]),
                        ),
                      ],
                    ],
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