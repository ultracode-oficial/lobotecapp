double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

int? _toInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

class DashboardModel {
  final int ordensDoDia;
  final int etapasFeitas;
  final int etapasTotal;
  final int? tempoMedioMinutos;
  final ProximoServicoModel? proximoServico;

  DashboardModel({
    required this.ordensDoDia,
    required this.etapasFeitas,
    required this.etapasTotal,
    this.tempoMedioMinutos,
    this.proximoServico,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }
    return DashboardModel(
      ordensDoDia: _toInt(json['ordens_do_dia']) ?? 0,
      etapasFeitas: _toInt(json['etapas_feitas']) ?? 0,
      etapasTotal: _toInt(json['etapas_total']) ?? 0,
      tempoMedioMinutos: _toInt(json['tempo_medio_minutos']),
      proximoServico: json['proximo_servico'] != null &&
              json['proximo_servico'] is Map<String, dynamic>
          ? ProximoServicoModel.fromJson(
              json['proximo_servico'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProximoServicoModel {
  final int etapaId;
  final int servicoId;
  final String? numeroOs;
  final String? statusEtapa;
  final String? horarioInicio;
  final ClienteResumoModel? cliente;

  ProximoServicoModel({
    required this.etapaId,
    required this.servicoId,
    this.numeroOs,
    this.statusEtapa,
    this.horarioInicio,
    this.cliente,
  });

  factory ProximoServicoModel.fromJson(Map<String, dynamic> json) {
    int servicoId = _toInt(json['servico_id']) ?? 0;
    String? numOs = json['numero_os']?.toString() ?? json['identificador']?.toString();
    if (json['servico'] is Map) {
      final s = json['servico'] as Map;
      if (servicoId == 0) {
        servicoId = _toInt(s['id']) ?? 0;
      }
      numOs ??= s['codigo']?.toString() ?? s['numero_os']?.toString();
    }

    return ProximoServicoModel(
      etapaId: _toInt(json['etapa_id']) ?? _toInt(json['id']) ?? 0,
      servicoId: servicoId,
      numeroOs: numOs,
      statusEtapa: json['status_etapa']?.toString() ?? json['status']?.toString(),
      horarioInicio: json['horario_inicio']?.toString() ??
          json['data_inicio']?.toString() ??
          json['data_hora_inicial']?.toString(),
      cliente: json['cliente'] != null && json['cliente'] is Map<String, dynamic>
          ? ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : (json['cliente'] is Map
              ? ClienteResumoModel.fromJson(Map<String, dynamic>.from(json['cliente'] as Map))
              : null),
    );
  }
}

class ClienteResumoModel {
  final int id;
  final String nome;
  final String? endereco;
  final double? lat;
  final double? lng;

  ClienteResumoModel({
    required this.id,
    required this.nome,
    this.endereco,
    this.lat,
    this.lng,
  });

  factory ClienteResumoModel.fromJson(Map<String, dynamic> json) {
    return ClienteResumoModel(
      id: _toInt(json['id']) ?? 0,
      nome: json['nome']?.toString() ?? json['razao_social']?.toString() ?? 'Cliente',
      endereco: json['endereco']?.toString() ?? json['logradouro']?.toString(),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }
}
