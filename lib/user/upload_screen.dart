import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../ai_service.dart';
import '../firestore_helper.dart';
import '../image_service.dart';
import 'location_confirm_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  bool _analyzing = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _error = null;
      });
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _analyzing = true);

    final compressed = await ImageService.compressForAI(_image!);
    final result = await AIService.detectPothole(compressed);

    if (!mounted) return;
    setState(() => _analyzing = false);

    if (result == null || result['isPothole'] != true) {
      setState(() => _error =
          'Pothole not detected. Upload a clearer road photo.');
      return;
    }

    final loc = await Navigator.push<Map<String, double>>(
      context,
      MaterialPageRoute(builder: (_) => const LocationConfirmScreen()),
    );
    if (loc == null) return;

    final upload = await ImageService.compressForUpload(_image!);

    await FirestoreHelper.addTicket({
      'photoPath': upload.path,
      'lat': loc['lat'],
      'lng': loc['lng'],
      'type': result['type'],
      'severity': result['severity'],
      'confidence': result['confidence'],
      'status': 'pending',
      'contractor': null,
      'proofPath': null,
      'verified': null,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ticket sent to Mayor for approval')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Pothole'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.3), width: 2),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_image!,
                          fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 60,
                            color: Colors.teal.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        const Text('Tap to upload photo',
                            style: TextStyle(
                                fontSize: 16, color: Colors.teal)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red))),
              ]),
            ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ANALYZE WITH AI',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _image == null || _analyzing ? null : _analyze,
            ),
          ),
          if (_analyzing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}