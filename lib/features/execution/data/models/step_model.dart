import 'dashboard_model.dart';
import 'equipment_model.dart';

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

bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val == 1 || val == '1' || val == 'true') return true;
  return false;
}

class StepModel {
  final int id;
  final int? servicoId;
  final String? titulo;
  final String status;
  final String? dataInicio;
  final String? dataFim;
  final String? checkInAt;
  final double? checkInLat;
  final double? checkInLng;
  final String? assinaturaUrl;
  final String? numeroOs;
  final String? tipoServicoNome;
  final ClienteResumoModel? cliente;
  final List<EquipmentModel> equipamentos;
  final int? equipamentosTotal;
  final int? equipamentosDone;
  final List<String> colegas;
  final bool temAssinatura;

  StepModel({
    required this.id,
    this.servicoId,
    this.titulo,
    required this.status,
    this.dataInicio,
    this.dataFim,
    this.checkInAt,
    this.checkInLat,
    this.checkInLng,
    this.assinaturaUrl,
    this.numeroOs,
    this.tipoServicoNome,
    this.cliente,
    this.equipamentos = const [],
    this.equipamentosTotal,
    this.equipamentosDone,
    this.colegas = const [],
    this.temAssinatura = false,
  });

  bool get isCheckedIn =>
      status == 'EM_ANDAMENTO' ||
      status == 'FINALIZADO' ||
      checkInAt != null;

  bool get isFinalized => status == 'FINALIZADO';

  StepModel copyWith({
    int? id,
    int? servicoId,
    String? titulo,
    String? status,
    String? dataInicio,
    String? dataFim,
    String? checkInAt,
    double? checkInLat,
    double? checkInLng,
    String? assinaturaUrl,
    String? numeroOs,
    String? tipoServicoNome,
    ClienteResumoModel? cliente,
    List<EquipmentModel>? equipamentos,
    int? equipamentosTotal,
    int? equipamentosDone,
    List<String>? colegas,
    bool? temAssinatura,
  }) {
    return StepModel(
      id: id ?? this.id,
      servicoId: servicoId ?? this.servicoId,
      titulo: titulo ?? this.titulo,
      status: status ?? this.status,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      assinaturaUrl: assinaturaUrl ?? this.assinaturaUrl,
      numeroOs: numeroOs ?? this.numeroOs,
      tipoServicoNome: tipoServicoNome ?? this.tipoServicoNome,
      cliente: cliente ?? this.cliente,
      equipamentos: equipamentos ?? this.equipamentos,
      equipamentosTotal: equipamentosTotal ?? this.equipamentosTotal,
      equipamentosDone: equipamentosDone ?? this.equipamentosDone,
      colegas: colegas ?? this.colegas,
      temAssinatura: temAssinatura ?? this.temAssinatura,
    );
  }

  factory StepModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }

    var rawEq = json['equipamentos'];
    List<EquipmentModel> eqList = [];
    if (rawEq is List) {
      eqList = rawEq
          .whereType<Map>()
          .map((e) => EquipmentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    var rawColegas = json['users'] ?? json['colegas'];
    List<String> colList = [];
    if (rawColegas is List) {
      for (var c in rawColegas) {
        if (c is String) {
          colList.add(c);
        } else if (c is Map && c['name'] != null) {
          colList.add(c['name'] as String);
        }
      }
    }

    String? tipoNome;
    if (json['servico'] is Map && json['servico']['tipo_servico'] is Map) {
      tipoNome = json['servico']['tipo_servico']['name']?.toString();
    } else if (json['tipo_servico_nome'] != null) {
      tipoNome = json['tipo_servico_nome']?.toString();
    }

    ClienteResumoModel? clienteResumo;
    if (json['cliente'] is Map<String, dynamic>) {
      clienteResumo = ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>);
    } else if (json['cliente'] is Map) {
      clienteResumo = ClienteResumoModel.fromJson(Map<String, dynamic>.from(json['cliente'] as Map));
    }

    final totalEq = _toInt(json['equipamentos_total']) ??
        (_toInt(json['equipamentos_count']) ?? eqList.length);
    final doneEq = _toInt(json['equipamentos_done']) ??
        eqList.where((e) => e.isFinalizado).length;

    return StepModel(
      id: _toInt(json['id']) ?? 0,
      servicoId: _toInt(json['servico_id']) ??
          (json['servico'] is Map ? _toInt(json['servico']['id']) : null),
      titulo: json['titulo']?.toString() ??
          (json['numero_etapa'] != null
              ? 'Etapa ${json['numero_etapa']}'
              : 'Etapa ${json['id']}'),
      status: json['status']?.toString() ?? 'AGUARDANDO',
      dataInicio: json['data_inicio']?.toString() ??
          json['data_hora_inicial']?.toString() ??
          json['data']?.toString(),
      dataFim: json['data_fim']?.toString() ??
          json['data_hora_final']?.toString(),
      checkInAt: json['check_in_at']?.toString() ?? json['checkin_at']?.toString(),
      checkInLat: _toDouble(json['check_in_lat']) ?? _toDouble(json['checkin_lat']),
      checkInLng: _toDouble(json['check_in_lng']) ?? _toDouble(json['checkin_lng']),
      assinaturaUrl: json['assinatura_url']?.toString(),
      numeroOs: json['numero_os']?.toString() ??
          (json['servico'] is Map ? json['servico']['codigo']?.toString() : null) ??
          json['identificador']?.toString(),
      tipoServicoNome: tipoNome,
      cliente: clienteResumo,
      equipamentos: eqList,
      equipamentosTotal: totalEq,
      equipamentosDone: doneEq,
      colegas: colList,
      temAssinatura: _toBool(json['tem_assinatura']) ||
          (json['assinatura_url'] != null && json['assinatura_url'].toString().isNotEmpty),
    );
  }
}
