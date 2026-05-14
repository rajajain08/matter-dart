import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/home_page.dart';
import 'ui/web_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  runApp(const MatterDartDemoApp());
}

class MatterDartDemoApp extends StatelessWidget {
  const MatterDartDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFF0B0C14);
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    return MaterialApp(
      title: 'Matter Dart Demos',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF60A5FA),
          secondary: Color(0xFFF59E0B),
          surface: Color(0xFF14151F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFFE5E7EB),
          displayColor: Colors.white,
          fontFamily: kIsWeb ? 'DM Sans' : null,
        ),
      ),
      home: kIsWeb ? const WebDemoHomePage() : const HomePage(),
    );
  }
}
