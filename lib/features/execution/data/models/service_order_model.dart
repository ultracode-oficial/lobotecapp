import 'step_model.dart';
import 'dashboard_model.dart';

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

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
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
      tipoNome = json['tipo_servico']['nome'] as String? ?? '';
    } else if (json['tipo_servico_nome'] is String) {
      tipoNome = json['tipo_servico_nome'] as String;
    }

    return ServiceOrderModel(
      id: json['id'] as int? ?? 0,
      numeroOs: json['numero_os'] as String? ??
          json['identificador'] as String? ??
          '#${json['id']}',
      status: json['status'] as String? ?? 'CONFIRMADO',
      prioridade: json['prioridade'] as String?,
      modalidade: json['modalidade'] as String?,
      descricao: json['descricao'] as String? ?? json['observacoes'] as String?,
      cliente: json['cliente'] != null && json['cliente'] is Map<String, dynamic>
          ? ClienteResumoModel.fromJson(json['cliente'] as Map<String, dynamic>)
          : null,
      tipoServicoNome: tipoNome,
      proximaEtapa: json['proxima_etapa'] != null &&
              json['proxima_etapa'] is Map<String, dynamic>
          ? StepModel.fromJson(json['proxima_etapa'] as Map<String, dynamic>)
          : null,
      etapasClosed: json['etapas_closed'] as int? ?? 0,
      etapasTotal: json['etapas_total'] as int? ??
          (json['etapas_count'] as int? ?? etapasList.length),
      podeFinalizarOs: json['pode_finalizar_os'] as bool? ?? false,
      etapasAbertas: json['etapas_abertas'] as int?,
      etapas: etapasList,
    );
  }
}
