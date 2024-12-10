import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'registro.dart'; // importa a classe Registro

class DadosRegistrados {
  // Mapa estático que armazena os pontos por registro ID
  static final Map<String, List<Registro>> pontos = {};

  static Future<void> salvarDados() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Serializa os registros para JSON
    Map<String, List<Map<String, dynamic>>> jsonData = {};
    pontos.forEach((key, listaRegistros) {
      jsonData[key] =
          listaRegistros.map((registro) => registro.toMap()).toList();
    });
    await prefs.setString('pontosRegistrados', jsonEncode(jsonData));
  }

  static Future<void> carregarDados() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('pontosRegistrados');
    if (jsonData != null) {
      Map<String, dynamic> data = jsonDecode(jsonData);
      pontos.clear();
      data.forEach((key, value) {
        pontos[key] =
            List<Registro>.from(value.map((item) => Registro.fromMap(item)));
      });
    }
  }

  static List<Registro> getPontosDoRegistro(String registroId) {
    return pontos[registroId] ?? [];
  }
}
