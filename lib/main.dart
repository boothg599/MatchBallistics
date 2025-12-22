import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EmpiricalDopeApp());
}

class EmpiricalDopeApp extends StatelessWidget {
  const EmpiricalDopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..loadProfiles(),
      child: MaterialApp(
        title: 'Empirical Dope',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF0f1115),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
