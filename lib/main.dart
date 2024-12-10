import 'package:aderencia/db_service.dart';
import 'package:flutter/material.dart';
import 'menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DadosRegistrados.carregarDados();
  runApp(const ColetorAderenciaApp());
}

class ColetorAderenciaApp extends StatelessWidget {
  const ColetorAderenciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coletor de Aderência',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
