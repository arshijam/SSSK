import 'firestore_helper.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(
      String phone, String password, String role) async {
    final users = await FirestoreHelper.getUsers();
    for (final u in users) {
      if (u['phone'] == phone &&
          u['password'] == password &&
          u['role'] == role) {
        if (role == 'contractor' && u['isApproved'] != 1) {
          return {'error': 'Contractor pending approval by Mayor team'};
        }
        return u;
      }
    }
    return null;
  }

  static Future<String> registerUser({
    required String name,
    required String phone,
    required String address,
    required String password,
    required String role,
    String? selfiePath,
  }) async {
    return FirestoreHelper.addUser({
      'name': name,
      'phone': phone,
      'address': address,
      'password': password,
      'role': role,
      'isApproved': role == 'contractor' ? 0 : 1,
      'selfiePath': selfiePath,
    });
  }

  static Future<void> approveContractor(String docId) async {
    await FirestoreHelper.updateUser(docId, {'isApproved': 1});
  }

  static Future<void> rejectContractor(String docId) async {
    await FirestoreHelper.updateUser(docId, {'isApproved': -1});
  }
}