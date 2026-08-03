import 'package:classmates/screens/onbarding/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the complete Classmates home screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(317, 690));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('CLASSMATES'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Homeschooling Adventures'), findsOneWidget);
    expect(find.text('Take a tour'), findsOneWidget);
    expect(find.text('Let’s get started'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);

    final buttonSize = tester.getSize(
      find.ancestor(
        of: find.text('Let’s get started'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(buttonSize.height, 48);
    expect(buttonSize.width, lessThanOrEqualTo(378));

    await tester.tap(find.text('Let’s get started'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
