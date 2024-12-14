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
  final int itemsPerPage = 5; // Defina o número de itens por página
  int currentPage = 0;

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
    _exportarCSV(id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              registros.removeWhere((registro) => registro['id'] == id);
              List<String> registrosJson =
                  registros.map((registro) => json.encode(registro)).toList();
              await prefs.setStringList('registros', registrosJson);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
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
          final String road = registroSelecionado['rodovia'];
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final String filePath = '${directory.path}/$road $timestamp.csv';

          // Salvar o arquivo
          final File file = File(filePath);
          await file.writeAsString(csvData);

          // Exibir sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Dados exportados com sucesso para $filePath')),
          );
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
    final int totalPages = (registros.length / itemsPerPage).ceil();
    final int startIndex = currentPage * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage) > registros.length
        ? registros.length
        : startIndex + itemsPerPage;
    final List<Map<String, dynamic>> currentPageRecords =
        registros.sublist(startIndex, endIndex);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aderência'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card de Cadastro
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cadastrar Registro',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid com 3 campos
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rodoviaController,
                            decoration: const InputDecoration(
                              labelText: 'Rodovia',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: operadorController,
                            decoration: const InputDecoration(
                              labelText: 'Operador',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: volumeController,
                            decoration: const InputDecoration(
                              labelText: 'Volume de Areia (cm³)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Botão de ação
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _salvarRegistro,
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tabela de Registros
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Rodovia')),
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: currentPageRecords.map((registro) {
                                return DataRow(cells: [
                                  DataCell(Text(registro['rodovia']!)),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      FormScreen(
                                                          menuId:
                                                              registro['id'])));
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () =>
                                            _exportarCSV(registro['id']),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _excluirRegistro(registro['id']),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      // Paginação
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: currentPage > 0
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text('Página ${currentPage + 1} de $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: currentPage < totalPages - 1
                                ? () {
                                    setState(() {
                                      currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
