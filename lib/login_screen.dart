import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'user/user_home.dart';
import 'mayor/mayor_dashboard.dart';
import 'contractor/contractor_jobs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String role = 'user';
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    final user = await AuthService.login(
        phoneCtrl.text.trim(), passCtrl.text.trim(), role);
    if (!mounted) return;
    setState(() => loading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')));
      return;
    }
    if (user['error'] != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(user['error'])));
      return;
    }

    Widget page;
    if (role == 'user') {
      page = const UserHome();
    } else if (role == 'mayor') {
      page = const MayorDashboard();
    } else {
      page = const ContractorJobs();
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saaf Sarak Saaf Karachi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.location_city, size: 80, color: Colors.teal),
          const SizedBox(height: 16),
          const Center(
              child: Text('Saaf Sarak, Saaf Karachi',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold))),
          const SizedBox(height: 30),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(
                labelText: 'Role', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('Citizen')),
              DropdownMenuItem(value: 'mayor', child: Text('Mayor')),
              DropdownMenuItem(
                  value: 'contractor', child: Text('Contractor')),
            ],
            onChanged: (v) => setState(() => role = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Phone', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : _login,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('Register as User or Contractor'),
          ),
        ],
      ),
    );
  }
}