import 'dashboard_model.dart';
import 'equipment_model.dart';

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
  final ClienteResumoModel? cliente;
  final List<EquipmentModel> equipamentos;
  final List<String> colegas;

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
    this.cliente,
    this.equipamentos = const [],
    this.colegas = const [],
  });

  bool get isCheckedIn =>
      status == 'EM_ANDAMENTO' ||
      status == 'FINALIZADO' ||
      checkInAt != null;

  bool get isFinalized => status == 'FINALIZADO';

  factory StepModel.fromJson(Map<String, dynamic> json) {
    var rawEq = json['equipamentos'];
    List<EquipmentModel> eqList = [];
    if (rawEq is List) {
      eqList = rawEq
          .whereType<Map<String, dynamic>>()
          .map((e) => EquipmentModel.fromJson(e))
          .toList();
    }

    var rawColegas = json['colegas'];
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

    return StepModel(
      id: json['id'] as int? ?? 0,
      servicoId: json['servico_id'] as int?,
      titulo: json['titulo'] as String? ??
          (json['numero_etapa'] != null
              ? 'Etapa ${json['numero_etapa']}'
              : 'Etapa ${json['id']}'),
      status: json['status'] as String? ?? 'AGUARDANDO',
      dataInicio: json['data_inicio'] as String? ?? json['data'] as String?,
      dataFim: json['data_fim'] as String?,
      checkInAt: json['check_in_at'] as String?,
      checkInLat: json['check_in_lat'] != null
          ? (json['check_in_lat'] as num).toDouble()
          : null,
      checkInLng: json['check_in_lng'] != null
          ? (json['check_in_lng'] as num).toDouble()
          : null,
      assinaturaUrl: json['assinatura_url'] as String?,
      numeroOs: json['numero_os'] as String? ?? json['identificador'] as String?,
      cliente: json['cliente'] != null && json['cliente'] is Map<String, dynamic>
          ? ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      equipamentos: eqList,
      colegas: colList,
    );
  }
}
