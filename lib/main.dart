import 'package:flutter/material.dart';
import 'screens/menu_screen.dart'; // Importa a MenuScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove o banner de debug
      title: 'Aplicativo de Aderência',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MenuScreen(), // Tela inicial
    );
  }
}
