import 'package:aderencia/registro.dart';
import 'db_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class FormScreen extends StatefulWidget {
  final int registroId;
  final String rodovia;
  final String data;
  final String volume;
  final String operador;

  const FormScreen(
      {super.key,
      required this.registroId,
      required this.rodovia,
      required this.data,
      required this.volume,
      required this.operador});

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  // Controladores de texto
  final _pistaController = TextEditingController();
  final _sentidoController = TextEditingController();
  final _faixaController = TextEditingController();
  final _posicaoController = TextEditingController();
  final _trilhaController = TextEditingController();
  final _tipoController = TextEditingController();
  final _tempoController = TextEditingController();
  final _temperaturaController = TextEditingController();
  final _diametrosControllers =
      List.generate(4, (_) => TextEditingController());
  final _vrdControllers = List.generate(5, (_) => TextEditingController());
  final _observacaoController = TextEditingController();

  // Coordenadas de localização
  double _latitude = 0;
  double _longitude = 0;

  // Lista de fotos
  final List<String> _fotos = [];

  // Lista de pontos registrados por ID
  static final Map<int, List<Map<String, dynamic>>> _pontosRegistrados = {};
  List<Map<String, dynamic>> pontos = [];

  @override
  void initState() {
    super.initState();
    _carregarPontos();
    _obterLocalizacao();
    _requestPermissions();

    // Carregar pontos previamente registrados
    if (_pontosRegistrados[widget.registroId] == null) {
      _pontosRegistrados[widget.registroId] = [];
    }
  }

  void _carregarPontos() {
    setState(() {
      // Inicializa a lista de pontos para o registro, se não existir
      _pontosRegistrados[widget.registroId] = [];

      // Carrega os pontos do banco e adiciona
      List<Registro> pontosCarregados =
          DadosRegistrados.getPontosDoRegistro(widget.registroId.toString());
      _pontosRegistrados[widget.registroId]?.addAll(pontosCarregados as Iterable<
          Map<String,
              dynamic>>); // Não é mais um erro pois _pontosRegistrados aceita List<Registro>
    });
  }

  String _obterValorRegistro(int registroId, String chave) {
    if (!DadosRegistrados.pontos.containsKey(registroId.toString())) {
      print('Registro $registroId não encontrado.');
      return '';
    }

    final registros = DadosRegistrados.pontos[registroId.toString()];
    if (registros == null || registros.isEmpty) {
      print('Nenhum registro encontrado para $registroId.');
      return '';
    }

    final primeiroRegistro = registros[0];

    // Aqui verificamos se a propriedade existe no objeto Registro usando "chave"
    switch (chave) {
      case 'rodovia':
        return primeiroRegistro.rodovia;
      case 'data':
        return primeiroRegistro.data.toIso8601String();
      case 'operador':
        return primeiroRegistro.condicaoTempo;
      case 'volume':
        return primeiroRegistro.temperatura.toString();
      // Adicione outras propriedades conforme necessário
      default:
        print('Chave "$chave" não encontrada no registro $registroId.');
        return '';
    }
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _obterLocalizacao() async {
    try {
      // Verifica se a permissão foi concedida
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permissão de localização negada.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permissão de localização negada')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permissão de localização permanentemente negada.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Permissão de localização permanentemente negada. Ative manualmente.')),
        );
        return;
      }

      // Verifica se o serviço de localização está ativado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Serviço de localização está desativado.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Serviço de localização desativado. Ative o GPS.')),
        );
        return;
      }

      // Obtém a posição atual
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      print('Localização obtida: Lat: $_latitude, Long: $_longitude');
    } catch (e) {
      print('Erro ao obter localização: $e');
      setState(() {
        _latitude = 0;
        _longitude = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  // Método para capturar localização
  void _Localizacao() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se o serviço de localização está ativado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ative o serviço de localização')),
      );
      return;
    }

    // Verifica permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de localização negada')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Permissão de localização permanentemente negada. Configure nas permissões do dispositivo.')),
      );
      return;
    }
  }

  Future<void> _capturarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Gerar nome único para a imagem
      final uniqueName = const Uuid().v4();
      final directory = Directory('/storage/emulated/0/Download');
      final imagePath = '${directory.path}/$uniqueName.jpg';

      // Salvar a imagem localmente
      final File imageFile = File(image.path);
      await imageFile.copy(imagePath);

      // Atualizar estado com o novo nome da foto
      setState(() {
        _fotos.add(uniqueName); // Apenas o nome único é armazenado
      });
    }
  }

  void _cadastrarPonto() {
    // ignore: unused_local_variable
    double mediaDiametros = _diametrosControllers
            .map((controller) => double.tryParse(controller.text) ?? 0.0)
            .reduce((a, b) => a + b) /
        _diametrosControllers.length;

    // ignore: unused_local_variable
    double mediaVRDs = _vrdControllers
            .map((controller) => double.tryParse(controller.text) ?? 0.0)
            .reduce((a, b) => a + b) /
        _vrdControllers.length;

    final novoPonto = Registro(
      id: widget.registroId,
      rodovia: widget.rodovia,
      sentido: _sentidoController.text,
      pista: _pistaController.text,
      posicao: double.tryParse(_posicaoController.text) ?? 0.0,
      trilha: _trilhaController.text,
      tipoRevestimento: _tipoController.text,
      condicaoTempo: _tempoController.text,
      temperatura: double.tryParse(_temperaturaController.text) ?? 0.0,
      diametros: _diametrosControllers
          .map((c) => double.tryParse(c.text) ?? 0.0)
          .toList(),
      vrds: _vrdControllers.map((c) => double.tryParse(c.text) ?? 0.0).toList(),
      observacao: _observacaoController.text,
      latitude: double.tryParse(_latitude as String) ?? 0.0,
      longitude: double.tryParse(_longitude as String) ?? 0.0,
      fotos: _fotos,
      data: DateTime.now(),
      operador: widget.operador,
      volume: widget.volume,
      faixa: _faixaController.text,
    );

    setState(() {
      _pontosRegistrados[widget.registroId]
          ?.add(novoPonto as Map<String, dynamic>);
      DadosRegistrados.pontos[widget.registroId.toString()]?.add(novoPonto);
    });

    DadosRegistrados.salvarDados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ponto cadastrado com sucesso!')),
    );
  }

  void _voltarParaMenu() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Pontos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Primeira linha: Pista, Sentido, Faixa, Posição
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pistaController,
                    decoration: const InputDecoration(labelText: 'Pista'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _sentidoController,
                    decoration: const InputDecoration(labelText: 'Sentido'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _faixaController,
                    decoration: const InputDecoration(labelText: 'Faixa'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _posicaoController,
                    decoration:
                        const InputDecoration(labelText: 'Posição (km/est)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Segunda linha: Trilha, Tipo, Condição de Tempo, Temperatura
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _trilhaController,
                    decoration: const InputDecoration(labelText: 'Trilha'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _tipoController,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de Revestimento'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _tempoController,
                    decoration:
                        const InputDecoration(labelText: 'Condição de Tempo'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _temperaturaController,
                    decoration:
                        const InputDecoration(labelText: 'Temperatura (ºC)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Terceira linha: Diâmetros
            Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: TextField(
                    controller: _diametrosControllers[index],
                    decoration:
                        InputDecoration(labelText: 'Diâmetro ${index + 1}'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quarta linha: VRDs
            Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: TextField(
                    controller: _vrdControllers[index],
                    decoration: InputDecoration(labelText: 'VRD ${index + 1}'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quinta linha: Observação
            TextField(
              controller: _observacaoController,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),
            const SizedBox(height: 8),

            // Sexta linha: Latitude e Longitude
            Row(
              children: [
                Expanded(
                  child: Text('Latitude: $_latitude'),
                ),
                Expanded(
                  child: Text('Longitude: $_longitude'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sétima linha: Fotos capturadas
            Text('Fotos: ${_fotos.join('|')}'),
            const SizedBox(height: 16),

            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _cadastrarPonto,
                  child: const Text('Cadastrar'),
                ),
                ElevatedButton(
                  onPressed: _voltarParaMenu,
                  child: const Text('Voltar'),
                ),
                ElevatedButton(
                  onPressed: _capturarFoto,
                  child: const Text('Tirar Foto'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabela com pontos registrados
            Expanded(
              child: ListView.builder(
                itemCount: _pontosRegistrados[widget.registroId]?.length ?? 0,
                itemBuilder: (context, index) {
                  final ponto = _pontosRegistrados[widget.registroId]![index];

                  // Verifique se latitude ou longitude é null
                  if (ponto['latitude'] == null || ponto['longitude'] == null) {
                    return const SizedBox.shrink(); // Retorna um widget vazio
                  }

                  return Card(
                    child: ListTile(
                      title:
                          Text('Sentido: ${ponto['sentido'] ?? 'Indefinido'}'),
                      subtitle: Text(
                        'Posição: ${ponto['posicao'] ?? 'Indefinida'} | Média D: ${ponto['mediaDiametros'] ?? 'Indefinida'} | Média VRD: ${ponto['mediaVRDs'] ?? 'Indefinida'}',
                      ),
                      trailing: Text(
                        'Lat: ${ponto['latitude']} | Long: ${ponto['longitude']}',
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
