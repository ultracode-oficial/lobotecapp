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
    return DashboardModel(
      ordensDoDia: json['ordens_do_dia'] as int? ?? 0,
      etapasFeitas: json['etapas_feitas'] as int? ?? 0,
      etapasTotal: json['etapas_total'] as int? ?? 0,
      tempoMedioMinutos: json['tempo_medio_minutos'] != null
          ? (json['tempo_medio_minutos'] as num).toInt()
          : null,
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
    return ProximoServicoModel(
      etapaId: json['etapa_id'] as int? ?? json['id'] as int? ?? 0,
      servicoId: json['servico_id'] as int? ?? 0,
      numeroOs: json['numero_os'] as String? ?? json['identificador'] as String?,
      statusEtapa: json['status_etapa'] as String? ?? json['status'] as String?,
      horarioInicio: json['horario_inicio'] as String? ?? json['data_inicio'] as String?,
      cliente: json['cliente'] != null && json['cliente'] is Map<String, dynamic>
          ? ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
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
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ?? json['razao_social'] as String? ?? 'Cliente',
      endereco: json['endereco'] as String? ?? json['logradouro'] as String?,
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
    );
  }
}
