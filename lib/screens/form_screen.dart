import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class FormScreen extends StatefulWidget {
  final int menuId; // Recebe o ID da MenuScreen

  const FormScreen({super.key, required this.menuId});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController pistaController = TextEditingController();
  final TextEditingController faixaController = TextEditingController();
  final TextEditingController posicaoController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController condicaoController = TextEditingController();
  final TextEditingController temperaturaController = TextEditingController();
  final TextEditingController d1Controller = TextEditingController();
  final TextEditingController d2Controller = TextEditingController();
  final TextEditingController d3Controller = TextEditingController();
  final TextEditingController d4Controller = TextEditingController();
  final TextEditingController v1Controller = TextEditingController();
  final TextEditingController v2Controller = TextEditingController();
  final TextEditingController v3Controller = TextEditingController();
  final TextEditingController v4Controller = TextEditingController();
  final TextEditingController v5Controller = TextEditingController();
  final TextEditingController obsController = TextEditingController();
  String latitude = '';
  String longitude = '';
  List<String> fotos = [];
  List<Map<String, dynamic>> pontos = [];
  final List<String> sentidoOptions = ['Crescente', 'Decrescente'];
  String? selectedSentido;
  final List<String> trilhaOptions = ['Interna', 'Externa'];
  String? selectedtrilha;
  static const platform = MethodChannel('com.seuapp/temperatura_bateria');
  double? temperaturaBateria;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  void _initScreen() async {
    await carregarPontos();
    await requestPermissions();
    await obterLocalizacao();
    await obterTemperaturaBateria();
  }

  Future<void> obterTemperaturaBateria() async {
    try {
      final double temperatura =
          await platform.invokeMethod('getBatteryTemperature');
      setState(() {
        temperaturaController.text = temperatura.toStringAsFixed(1);
      });
    } catch (e) {
      print("Erro ao obter temperatura : $e");
    }
  }

  Future<void> requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> carregarPontos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pontosSalvos = prefs.getString('pontos_${widget.menuId}');
    if (pontosSalvos != null) {
      setState(() {
        pontos = List<Map<String, dynamic>>.from(json.decode(pontosSalvos));
      });
    }
  }

  Future<void> salvarPonto() async {
    final novoPonto = {
      'menuId': widget.menuId,
      'data': DateTime.now().toString().split('.')[0],
      'sentido': selectedSentido,
      'pista': pistaController.text,
      'faixa': faixaController.text,
      'posicao': posicaoController.text,
      'trilha': selectedtrilha,
      'tipo': tipoController.text,
      'condicao': condicaoController.text,
      'temperatura': temperaturaController.text,
      'd1': d1Controller.text,
      'd2': d2Controller.text,
      'd3': d3Controller.text,
      'd4': d4Controller.text,
      'v1': v1Controller.text,
      'v2': v2Controller.text,
      'v3': v3Controller.text,
      'v4': v4Controller.text,
      'v5': v5Controller.text,
      'obs': obsController.text,
      'latitude': latitude,
      'longitude': longitude,
      'fotos': fotos.join(' | '),
    };
    setState(() {
      pontos.add(novoPonto);
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('pontos_${widget.menuId}', json.encode(pontos));
    limparCampos();
  }

  void limparCampos() {
    /*selectedSentido.clear();
    pistaController.clear();
    faixaController.clear();
    posicaoController.clear();
    selectedtrilha.clear();
    tipoController.clear();
    condicaoController.clear();
    temperaturaController.clear();*/
    d1Controller.clear();
    d2Controller.clear();
    d3Controller.clear();
    d4Controller.clear();
    v1Controller.clear();
    v2Controller.clear();
    v3Controller.clear();
    v4Controller.clear();
    v5Controller.clear();
    obsController.clear();
    fotos.clear();
  }

  Future<void> obterLocalizacao() async {
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
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      });

      print('Localização obtida: Lat: $latitude, Long: $longitude');
    } catch (e) {
      print('Erro ao obter localização: $e');
      setState(() {
        latitude = 'Erro ao obter';
        longitude = 'Erro ao obter';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  Future<void> capturarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Diretório onde a foto será salva
      final Directory directory = Directory('/storage/emulated/0/Download');
      final String uniqueFileName =
          'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = '${directory.path}/$uniqueFileName';

      // Caminho do arquivo original
      File originalImage = File(pickedFile.path);

      // Usando flutter_image_compress para compactar a imagem
      var result = await FlutterImageCompress.compressWithFile(
        originalImage.absolute.path,
        minWidth: 1920, // Largura mínima (ajuste conforme necessário)
        minHeight: 1080, // Altura mínima (ajuste conforme necessário)
        quality: 70, // Qualidade da compressão (ajuste conforme necessário)
        rotate: 0, // Caso queira rodar a imagem
      );

      if (result != null) {
        // Salvar a imagem compactada
        File(newPath).writeAsBytesSync(result);

        // Adicionar o nome da foto à lista
        setState(() {
          fotos.add(uniqueFileName);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Pontos')),
      body: Scrollbar(
        // Adiciona a barra de rolagem
        child: SingleChildScrollView(
          // Adiciona a rolagem na tela
          child: BootstrapContainer(
            fluid: true,
            padding: const EdgeInsets.all(16.0),
            children: [
              // Primeira linha de campos
              BootstrapRow(children: [
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sentido',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedSentido,
                      items: sentidoOptions.map((String sentido) {
                        return DropdownMenuItem<String>(
                          value: sentido,
                          child: Text(sentido),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSentido = newValue;
                        });
                      },
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: pistaController,
                      decoration: const InputDecoration(
                        labelText: 'Pista',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: faixaController,
                      decoration: const InputDecoration(
                        labelText: 'Faixa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: posicaoController,
                      decoration: const InputDecoration(
                        labelText: 'Posição (km/est)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ]),
              // Segunda linha de campos
              BootstrapRow(children: [
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Trilha',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedtrilha,
                      items: trilhaOptions.map((String trilha) {
                        return DropdownMenuItem<String>(
                          value: trilha,
                          child: Text(trilha),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedtrilha = newValue;
                        });
                      },
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: tipoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Revestimento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: condicaoController,
                      decoration: const InputDecoration(
                        labelText: 'Condição de Tempo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-6 col-md-3',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: temperaturaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Temperatura',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ]),

              // Terceira linha de campos
              BootstrapRow(
                children: [
                  BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: d1Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Diâmetro 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: d2Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Diâmetro 2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: d3Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Diâmetro 3',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: d4Controller,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Diâmetro 4',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Quarta linha de campos (VRD)
              BootstrapRow(children: [
                BootstrapCol(
                  sizes: 'col-12 col-sm-2 col-md-1',
                  child: const Text(''),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-4 col-md-2',
                  child: Container(
                    margin: const EdgeInsets.all(
                        8.0), // Margem de 8 pixels em todos os lados
                    child: TextField(
                      controller: v1Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'VRD 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-4 col-md-2',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: v2Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'VRD 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-4 col-md-2',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: v3Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'VRD 3',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-4 col-md-2',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: v4Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'VRD 4',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-12 col-sm-4 col-md-2',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: v5Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'VRD 5',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ]),
              // Campo de observação
              BootstrapRow(children: [
                BootstrapCol(
                  sizes: 'col-12',
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: obsController,
                      decoration: const InputDecoration(
                        labelText: 'Observação',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ]),

              // Botões de ação
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0), // Margem acima e abaixo
                child: Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Centraliza os botões horizontalmente
                  children: [
                    ElevatedButton(
                      onPressed: salvarPonto,
                      child: const Text('Cadastrar'),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre os botões
                    ElevatedButton(
                      onPressed: capturarFoto,
                      child: const Text('Foto'),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre os botões
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),

              // Tabela de pontos
              ListView.builder(
                shrinkWrap:
                    true, // Garante que a lista seja renderizada corretamente
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita a rolagem da ListView (porque o ScrollView já rola)
                itemCount: pontos.length,
                itemBuilder: (context, index) {
                  final ponto = pontos[index];
                  final d = ((double.tryParse(
                                  ponto['d1']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['d2']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['d3']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['d4']?.replaceAll(',', '.') ?? '0') ??
                              0)) /
                      4;

                  final v = ((double.tryParse(
                                  ponto['f1']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['f2']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['f3']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['f4']?.replaceAll(',', '.') ?? '0') ??
                              0) +
                          (double.tryParse(
                                  ponto['f5']?.replaceAll(',', '.') ?? '0') ??
                              0)) /
                      5;

                  return ListTile(
                    title: Text('Sentido: ${ponto['sentido'] ?? ''}'),
                    subtitle: Text(
                        'Posição: ${ponto['posicao'].replaceAll(',', '.')} | Ø: ${d.toStringAsFixed(2)} | VRD: ${v.toStringAsFixed(2)}'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
