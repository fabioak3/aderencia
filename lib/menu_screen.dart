import 'package:aderencia/registro.dart';
import 'db_service.dart';
import 'package:flutter/material.dart';
import 'form_screen.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Controladores para os campos
  final _rodoviaController = TextEditingController();
  final _dataController = TextEditingController();
  final _operadorController = TextEditingController();
  final _volumeController = TextEditingController(text: '25');

  // Lista de registros
  List<Map<String, dynamic>> registros = [];
  int idRegistroAtual = 1;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _dataController.text =
        DateTime.now().toString().split(' ')[0]; // Preenche a data atual
  }

  void _cadastrarRegistro() {
    if (_rodoviaController.text.isEmpty || _operadorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios!')),
      );
      return;
    }

    final novoRegistro = Registro(
      id: idRegistroAtual,
      rodovia: _rodoviaController.text,
      sentido: '',
      pista: '',
      posicao: 0.0,
      trilha: '',
      tipoRevestimento: '',
      condicaoTempo: '',
      temperatura: 00,
      diametros: [],
      vrds: [],
      observacao: '',
      latitude: 0.0,
      longitude: 0.0,
      fotos: [],
      data: DateTime.now(),
      operador: _operadorController.text,
      volume: _volumeController.text,
      faixa: '',
    );

    setState(() {
      // Adiciona o registro à lista principal
      registros.add({
        'id': idRegistroAtual,
        'rodovia': novoRegistro.rodovia,
        'data': novoRegistro.data.toIso8601String(),
        'operador': novoRegistro.operador,
        'volume': novoRegistro.volume,
      });

      // Adiciona o registro à estrutura de DadosRegistrados
      DadosRegistrados.pontos[idRegistroAtual.toString()] = [novoRegistro];
      idRegistroAtual++;
    });

    _rodoviaController.clear();
    _operadorController.clear();
    _volumeController.text = '25';

    // Salva os dados no SharedPreferences
    //DadosRegistrados.salvarDados();
  }

  void _irParaCadastroPontos(
      int id, String rodovia, String data, String volume, String operador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormScreen(
            registroId: id,
            rodovia: rodovia,
            data: data,
            volume: volume,
            operador: operador),
      ),
    );
  }

  void _excluirRegistro(int id) {
    setState(() {
      registros.removeWhere((registro) => registro['id'] == id);
      DadosRegistrados.pontos.remove(id.toString());
    });
    DadosRegistrados.salvarDados();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _carregarDados() async {
    await DadosRegistrados
        .carregarDados(); // Carrega os dados do SharedPreferences

    setState(() {
      // Preenche a lista de registros a partir dos dados carregados
      registros = DadosRegistrados.pontos.entries.map((entry) {
        final primeiroRegistro = entry.value.isNotEmpty ? entry.value[0] : null;
        return {
          'id': int.parse(entry.key),
          'rodovia': primeiroRegistro?.rodovia ?? '',
          'data': primeiroRegistro?.data.toIso8601String() ?? '',
          'operador': primeiroRegistro?.condicaoTempo ?? '',
          'volume': primeiroRegistro?.temperatura.toString() ?? '0'
        };
      }).toList();

      idRegistroAtual = registros.isNotEmpty ? registros.last['id'] + 1 : 1;
    });
  }

  Future<void> _exportarDados(String registroId) async {
    await _requestPermissions();
    try {
      final List<List<String>> rows = [
        [
          'Registro ID',
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

      final registros = DadosRegistrados.getPontosDoRegistro(registroId);
      for (var registro in registros) {
        rows.add([
          registroId,
          registro.rodovia,
          registro.data.toIso8601String(),
          registro.pista,
          registro.sentido,
          registro.faixa,
          registro.operador,
          registro.volume,
          registro.tipoRevestimento,
          registro.condicaoTempo,
          registro.temperatura.toString(),
          ...registro.diametros.map((d) => d.toString()),
          ...registro.vrds.map((v) => v.toString()),
          registro.observacao,
          registro.latitude.toString(),
          registro.longitude.toString(),
          registro.fotos.join('|'),
        ]);
      }

      final String csvData = const ListToCsvConverter().convert(rows);
      final Directory directory = Directory('/storage/emulated/0/Download');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String filePath = '${directory.path}/$timestamp.csv';

      final File file = File(filePath);
      await file.writeAsString(csvData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados exportados com sucesso para $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Principal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campos de entrada
            TextField(
              controller: _rodoviaController,
              decoration: const InputDecoration(labelText: 'Rodovia'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dataController,
              decoration: const InputDecoration(labelText: 'Data'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _operadorController,
              decoration: const InputDecoration(labelText: 'Operador'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _volumeController,
              decoration:
                  const InputDecoration(labelText: 'Volume de Areia (cm³)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _cadastrarRegistro,
              child: const Text('Cadastrar'),
            ),
            const SizedBox(height: 16),

            // Lista de registros
            Expanded(
              child: ListView.builder(
                itemCount: registros.length,
                itemBuilder: (context, index) {
                  final registro = registros[index];
                  return Card(
                    child: ListTile(
                      title: Text('Rodovia: ${registro['rodovia']}'),
                      subtitle: Text(
                        'Data: ${registro['data']} - Operador: ${registro['operador']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _irParaCadastroPontos(
                                registro['id'],
                                registro['rodovia'],
                                registro['data'],
                                registro['volume'],
                                registro['operador']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _exportarDados(registro['id']),
                            tooltip: 'Exportar Dados',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _excluirRegistro(registro['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
