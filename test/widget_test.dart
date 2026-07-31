import 'package:classmates/main.dart';
import 'package:classmates/screens/onbarding/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Classmates splash screen', (tester) async {
    await tester.pumpWidget(const ClassmatesApp());

    expect(find.text('CLASSMATES'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, ClassmatesColors.green);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Homeschooling Adventures'), findsOneWidget);
  });
}
