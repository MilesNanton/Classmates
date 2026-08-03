import 'package:classmates/screens/onbarding/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows email verification instructions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: VerifyEmailScreen(email: 'student@example.com')),
    );

    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
    expect(find.textContaining('student@example.com'), findsOneWidget);
    expect(find.text('Check Verification'), findsOneWidget);
    expect(find.text('Resend email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
