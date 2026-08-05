import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> saveSocialUserProfile({
  required User user,
  required String authProvider,
  String? preferredName,
}) async {
  final reference = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid);
  final snapshot = await reference.get();
  final existingName = snapshot.data()?['name'];
  final emailName = user.email?.split('@').first;
  final resolvedName = _firstNonEmpty([
    existingName is String ? existingName : null,
    user.displayName,
    preferredName,
    emailName,
    authProvider == 'apple' ? 'Apple User' : 'Google User',
  ]);

  if (snapshot.exists) {
    await reference.update({
      'name': resolvedName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return;
  }

  await reference.set({
    'uid': user.uid,
    'name': resolvedName,
    'email': user.email,
    'authProvider': authProvider,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

String _firstNonEmpty(List<String?> values) {
  return values
      .firstWhere((value) => value != null && value.trim().isNotEmpty)!
      .trim();
}
