import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'form_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> registros = [];

  final TextEditingController rodoviaController = TextEditingController();
  final TextEditingController operadorController = TextEditingController();
  final TextEditingController volumeController =
      TextEditingController(text: '25');
  List<Map<String, dynamic>> pontos = [];

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }

  Future<void> _carregarRegistros() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? registrosSalvos = prefs.getStringList('registros');
    if (registrosSalvos != null) {
      setState(() {
        registros = registrosSalvos
            .map((registro) => json.decode(registro) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _salvarRegistro() async {
    if (rodoviaController.text.isEmpty || operadorController.text.isEmpty) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> novoRegistro = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'rodovia': rodoviaController.text,
      'data': DateTime.now().toString().split(' ')[0],
      'operador': operadorController.text,
      'volume': volumeController.text,
    };

    registros.add(novoRegistro);
    List<String> registrosJson =
        registros.map((registro) => json.encode(registro)).toList();
    await prefs.setStringList('registros', registrosJson);

    rodoviaController.clear();
    operadorController.clear();
    volumeController.text = '25';
    setState(() {});
  }

  Future<void> _excluirRegistro(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    registros.removeWhere((registro) => registro['id'] == id);
    List<String> registrosJson =
        registros.map((registro) => json.encode(registro)).toList();
    await prefs.setStringList('registros', registrosJson);
    setState(() {});
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _exportarCSV(int id) async {
    await _requestPermissions();
    try {
      final registroSelecionado = registros
          .firstWhere((registro) => registro['id'] == id, orElse: () => {});

      if (registroSelecionado.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final String? pontosSalvos = prefs.getString('pontos_$id');

        if (pontosSalvos != null) {
          setState(() {
            pontos = List<Map<String, dynamic>>.from(json.decode(pontosSalvos));
          });

          final List<List<String>> rows = [
            [
              'Rodovia',
              'Data',
              'Pista',
              'Sentido',
              'Faixa',
              'Operador',
              'Volume',
              'KM',
              'Trilha',
              'Tipo',
              'Tempo',
              'Temperatura',
              'D1',
              'D2',
              'D3',
              'D4',
              'V1',
              'V2',
              'V3',
              'V4',
              'V5',
              'Obs',
              'Latitude',
              'Longitude',
              'Foto'
            ],
          ];

          for (var ponto in pontos) {
            rows.add([
              registroSelecionado['rodovia'] ?? '',
              ponto['data'] ?? '',
              ponto['pista'] ?? '',
              ponto['sentido'] ?? '',
              ponto['faixa'] ?? '',
              registroSelecionado['operador'] ?? '',
              registroSelecionado['volume'] ?? '',
              ponto['posicao'] ?? '',
              ponto['trilha'] ?? '',
              ponto['tipo'] ?? '',
              ponto['condicao'] ?? '',
              ponto['temperatura'] ?? '',
              ponto['d1'] ?? '',
              ponto['d2'] ?? '',
              ponto['d3'] ?? '',
              ponto['d4'] ?? '',
              ponto['v1'] ?? '',
              ponto['v2'] ?? '',
              ponto['v3'] ?? '',
              ponto['v4'] ?? '',
              ponto['v5'] ?? '',
              ponto['obs'] ?? '',
              ponto['latitude'] ?? '',
              ponto['longitude'] ?? '',
              ponto['fotos'] ?? ''
            ]);
          }

          // Converter para CSV
          final String csvData = const ListToCsvConverter().convert(rows);

          // Obter o diretório de download
          final Directory directory = Directory('/storage/emulated/0/Download');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final String filePath = '${directory.path}/$timestamp.csv';

          // Salvar o arquivo
          final File file = File(filePath);
          await file.writeAsString(csvData);

          // Exibir sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Dados exportados com sucesso para $filePath')),
          );

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Arquivo CSV exportado em $filePath')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Principal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: rodoviaController,
                decoration: const InputDecoration(labelText: 'Rodovia')),
            TextField(
                controller: operadorController,
                decoration: const InputDecoration(labelText: 'Operador')),
            TextField(
                controller: volumeController,
                decoration:
                    const InputDecoration(labelText: 'Volume de Areia (cm³)')),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _salvarRegistro, child: const Text('Cadastrar')),
            const SizedBox(height: 16),
            Expanded(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rodovia')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Operador')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: registros.map((registro) {
                  return DataRow(cells: [
                    DataCell(Text(registro['rodovia'])),
                    DataCell(Text(registro['data'])),
                    DataCell(Text(registro['operador'])),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        FormScreen(menuId: registro['id'])));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _exportarCSV(registro['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _excluirRegistro(registro['id']),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
