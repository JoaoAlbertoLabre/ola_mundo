import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'screens/login_screen.dart';

const bool resetarDb = false; // altere para true quando precisar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (resetarDb) {
    await DatabaseHelper.instance.resetDatabase();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Financeiro',
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        // '/novo_usuario': (context) => const NovoUsuarioScreen(),
        // '/confirmacao': (context) => ConfirmacaoScreen(email: ''), // só de exemplo
      }, // Tela inicial de login
    );
  }
}
