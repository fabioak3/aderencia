class Registro {
  int id;
  String rodovia;
  String operador;
  String volume;
  String sentido;
  String pista;
  double posicao;
  String trilha;
  String faixa;
  String tipoRevestimento;
  String condicaoTempo;
  double temperatura;
  List<double> diametros;
  List<double> vrds;
  String observacao;
  double latitude;
  double longitude;
  List<String> fotos;
  DateTime data;

  Registro({
    required this.id,
    required this.rodovia,
    required this.operador,
    required this.volume,
    required this.sentido,
    required this.pista,
    required this.posicao,
    required this.trilha,
    required this.faixa,
    required this.tipoRevestimento,
    required this.condicaoTempo,
    required this.temperatura,
    required this.diametros,
    required this.vrds,
    required this.observacao,
    required this.latitude,
    required this.longitude,
    required this.fotos,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rodovia': rodovia,
      'operador': operador,
      'volume': volume,
      'sentido': sentido,
      'pista': pista,
      'posicao': posicao,
      'trilha': trilha,
      'faixa': faixa,
      'tipoRevestimento': tipoRevestimento,
      'condicaoTempo': condicaoTempo,
      'temperatura': temperatura,
      'diametros': diametros,
      'vrds': vrds,
      'observacao': observacao,
      'latitude': latitude,
      'longitude': longitude,
      'fotos': fotos,
      'data': data.toIso8601String(),
    };
  }

  /// Converte um Mapa (JSON) para um objeto `Registro`
  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'],
      rodovia: map['rodovia'] ?? '',
      operador: map['operador'] ?? '',
      volume: map['volume'] ?? '',
      sentido: map['sentido'] ?? '',
      pista: map['pista'] ?? '',
      posicao: (map['posicao'] is double)
          ? map['posicao']
          : double.tryParse(map['posicao'].toString()) ?? 0.0,
      trilha: map['trilha'] ?? '',
      faixa: map['faixa'] ?? '',
      tipoRevestimento: map['tipoRevestimento'] ?? '',
      condicaoTempo: map['condicaoTempo'] ?? '',
      temperatura: (map['temperatura'] is double)
          ? map['temperatura']
          : double.tryParse(map['temperatura'].toString()) ?? 0.0,
      diametros: List<double>.from((map['diametros'] ?? [])
          .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)),
      vrds: List<double>.from((map['vrds'] ?? [])
          .map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0)),
      observacao: map['observacao'] ?? '',
      latitude: (map['latitude'] is double)
          ? map['latitude']
          : double.tryParse(map['latitude'].toString()) ?? 0.0,
      longitude: (map['longitude'] is double)
          ? map['longitude']
          : double.tryParse(map['longitude'].toString()) ?? 0.0,
      fotos: List<String>.from(map['fotos'] ?? []),
      data: DateTime.parse(map['data'] ?? DateTime.now().toString()),
    );
  }
}
