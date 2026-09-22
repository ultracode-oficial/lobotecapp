import 'step_model.dart';
import 'dashboard_model.dart';

int? _toInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val == 1 || val == '1' || val == 'true') return true;
  return false;
}

class ServiceOrderModel {
  final int id;
  final String numeroOs;
  final String status;
  final String? prioridade;
  final String? modalidade;
  final String? descricao;
  final ClienteResumoModel? cliente;
  final String? tipoServicoNome;
  final StepModel? proximaEtapa;
  final int etapasClosed;
  final int etapasTotal;
  final bool podeFinalizarOs;
  final int? etapasAbertas;
  final List<StepModel> etapas;

  ServiceOrderModel({
    required this.id,
    required this.numeroOs,
    required this.status,
    this.prioridade,
    this.modalidade,
    this.descricao,
    this.cliente,
    this.tipoServicoNome,
    this.proximaEtapa,
    this.etapasClosed = 0,
    this.etapasTotal = 0,
    this.podeFinalizarOs = false,
    this.etapasAbertas,
    this.etapas = const [],
  });

  ServiceOrderModel copyWith({
    int? id,
    String? numeroOs,
    String? status,
    String? prioridade,
    String? modalidade,
    String? descricao,
    ClienteResumoModel? cliente,
    String? tipoServicoNome,
    StepModel? proximaEtapa,
    int? etapasClosed,
    int? etapasTotal,
    bool? podeFinalizarOs,
    int? etapasAbertas,
    List<StepModel>? etapas,
  }) {
    return ServiceOrderModel(
      id: id ?? this.id,
      numeroOs: numeroOs ?? this.numeroOs,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      modalidade: modalidade ?? this.modalidade,
      descricao: descricao ?? this.descricao,
      cliente: cliente ?? this.cliente,
      tipoServicoNome: tipoServicoNome ?? this.tipoServicoNome,
      proximaEtapa: proximaEtapa ?? this.proximaEtapa,
      etapasClosed: etapasClosed ?? this.etapasClosed,
      etapasTotal: etapasTotal ?? this.etapasTotal,
      podeFinalizarOs: podeFinalizarOs ?? this.podeFinalizarOs,
      etapasAbertas: etapasAbertas ?? this.etapasAbertas,
      etapas: etapas ?? this.etapas,
    );
  }

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }

    var rawEtapas = json['etapas'];
    List<StepModel> etapasList = [];
    if (rawEtapas is List) {
      etapasList = rawEtapas
          .whereType<Map<String, dynamic>>()
          .map((e) => StepModel.fromJson(e))
          .toList();
    }

    String tipoNome = '';
    if (json['tipo_servico'] is Map) {
      tipoNome = (json['tipo_servico']['name'] ?? json['tipo_servico']['nome'])?.toString() ?? '';
    } else if (json['tipo_servico_nome'] is String) {
      tipoNome = json['tipo_servico_nome'] as String;
    }


    return ServiceOrderModel(
      id: _toInt(json['id']) ?? 0,
      numeroOs: json['numero_os']?.toString() ??
          json['identificador']?.toString() ??
          '#${json['id']}',
      status: json['status']?.toString() ?? 'CONFIRMADO',
      prioridade: json['prioridade']?.toString(),
      modalidade: json['modalidade']?.toString(),
      descricao: json['descricao']?.toString() ?? json['observacoes']?.toString(),
      cliente: json['cliente'] != null && json['cliente'] is Map<String, dynamic>
          ? ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      tipoServicoNome: tipoNome,
      proximaEtapa: json['proxima_etapa'] != null &&
              json['proxima_etapa'] is Map<String, dynamic>
          ? StepModel.fromJson(json['proxima_etapa'] as Map<String, dynamic>)
          : null,
      etapasClosed: _toInt(json['etapas_closed']) ?? 0,
      etapasTotal: _toInt(json['etapas_total']) ??
          (_toInt(json['etapas_count']) ?? etapasList.length),
      podeFinalizarOs: _toBool(json['pode_finalizar_os']),
      etapasAbertas: _toInt(json['etapas_abertas']),
      etapas: etapasList,
    );
  }
}
