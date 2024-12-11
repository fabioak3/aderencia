import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
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
  final TextEditingController sentidoController = TextEditingController();
  final TextEditingController pistaController = TextEditingController();
  final TextEditingController faixaController = TextEditingController();
  final TextEditingController posicaoController = TextEditingController();
  final TextEditingController trilhaController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    carregarPontos();
    obterGeolocalizacao();
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
      'sentido': sentidoController.text,
      'pista': pistaController.text,
      'faixa': faixaController.text,
      'posicao': posicaoController.text,
      'trilha': trilhaController.text,
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
      'observacao': obsController.text,
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
    /*sentidoController.clear();
    pistaController.clear();
    faixaController.clear();
    posicaoController.clear();
    trilhaController.clear();
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

  Future<void> obterGeolocalizacao() async {
    Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
    });
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
        minWidth: 800, // Largura mínima (ajuste conforme necessário)
        minHeight: 600, // Altura mínima (ajuste conforme necessário)
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
                    child: _buildTextField('Sentido', sentidoController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Pista', pistaController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Faixa', faixaController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child:
                        _buildTextField('Posição (km/est)', posicaoController)),
              ]),

              // Segunda linha de campos
              BootstrapRow(children: [
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Trilha', trilhaController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField(
                        'Tipo de Revestimento', tipoController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField(
                        'Condição de Tempo', condicaoController)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child:
                        _buildTextField('Temperatura', temperaturaController)),
              ]),

              // Terceira linha de campos
              BootstrapRow(children: [
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Diâmetro 1', d1Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Diâmetro 2', d2Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Diâmetro 3', d3Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-6 col-md-3',
                    child: _buildTextField('Diâmetro 4', d4Controller)),
              ]),

              // Quarta linha de campos (VRD)
              BootstrapRow(children: [
                BootstrapCol(
                  sizes: 'col-12 col-sm-2 col-md-1',
                  child: const Text(''),
                ), // Espaço à esquerda
                BootstrapCol(
                    sizes: 'col-12 col-sm-4 col-md-2',
                    child: _buildTextField('VRD 1', v1Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-4 col-md-2',
                    child: _buildTextField('VRD 2', v2Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-4 col-md-2',
                    child: _buildTextField('VRD 3', v3Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-4 col-md-2',
                    child: _buildTextField('VRD 4', v4Controller)),
                BootstrapCol(
                    sizes: 'col-12 col-sm-4 col-md-2',
                    child: _buildTextField('VRD 5', v5Controller)),
                BootstrapCol(
                  sizes: 'col-12 col-sm-2 col-md-1',
                  child: const Text(''),
                ), // Espaço à direita
              ]),

              // Campo de observação
              BootstrapRow(children: [
                BootstrapCol(
                    sizes: 'col-12 col-md-12',
                    child: _buildTextField('Observação', obsController)),
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
                      child: const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Cadastrar')),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre os botões
                    ElevatedButton(
                      onPressed: capturarFoto,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Foto'),
                      ),
                    ),
                    const SizedBox(width: 16), // Espaçamento entre os botões
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                          padding: EdgeInsets.all(16.0), child: Text('Voltar')),
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
                  return ListTile(
                    title: Text('Sentido: ${ponto['sentido']}'),
                    subtitle: Text(
                        'Posição: ${ponto['posicao']} | Coordenadas: ${ponto['latitude']} ${ponto['longitude']}'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
    );
  }
}
