import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onbarding/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: ClassmatesColors.green,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: ClassmatesColors.green,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ClassmatesApp());
}

class ClassmatesApp extends StatelessWidget {
  const ClassmatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Classmates',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
