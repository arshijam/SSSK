import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';
import 'ai_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = 'user';
  File? selfie;
  bool loading = false;

  Future<void> _pickSelfie() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front);
    if (img != null) setState(() => selfie = File(img.path));
  }

  Future<void> _register() async {
    if (selfie == null ||
        nameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill all required fields')));
      return;
    }
    setState(() => loading = true);
    final ok = await AIService.verifySelfie(selfie!);
    if (!ok) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selfie verification failed. Try again.')));
      return;
    }
    await AuthService.registerUser(
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      address: addrCtrl.text.trim(),
      password: passCtrl.text.trim(),
      role: role,
      selfiePath: selfie!.path,
    );
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(role == 'contractor'
            ? 'Registered! Waiting for Mayor approval.'
            : 'Registered. Please login.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(
                labelText: 'Register as', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('Citizen')),
              DropdownMenuItem(
                  value: 'contractor',
                  child: Text('Contractor (needs approval)')),
            ],
            onChanged: (v) => setState(() => role = v!),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(
                  labelText: 'Address', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          const Text('Selfie verification',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickSelfie,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16)),
              child: selfie != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(selfie!,
                          fit: BoxFit.cover, width: double.infinity))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt,
                            size: 50, color: Colors.teal),
                        const SizedBox(height: 8),
                        const Text('Tap to take selfie'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : _register,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}