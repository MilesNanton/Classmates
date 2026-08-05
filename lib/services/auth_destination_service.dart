import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> hasCompletedOnboarding(User user) async {
  try {
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['onboardingCompleted'] == true;
  } on FirebaseException {
    // The authenticated user should not be sent through onboarding again just
    // because their saved profile is temporarily unavailable.
    return true;
  }
}
