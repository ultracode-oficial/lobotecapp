import 'checklist_model.dart';
import 'task_model.dart';

class EquipmentModel {
  final int id; // ID de EquipamentoServico
  final int? equipamentoId;
  final String? tag;
  final bool isGeneric;
  final bool registroPendente;
  final bool checklistPendente;
  final bool cadastrado;
  final String status;
  final String? marca;
  final String? modelo;
  final String? tipoEquipamento;
  final String? btu;
  final String? evaporadora;
  final String? condensadora;
  final String? localizacao;
  final String? observacoes;
  final List<TaskModel> tarefas;
  final ChecklistModel? checklist;

  EquipmentModel({
    required this.id,
    this.equipamentoId,
    this.tag,
    this.isGeneric = false,
    this.registroPendente = false,
    this.checklistPendente = true,
    this.cadastrado = false,
    required this.status,
    this.marca,
    this.modelo,
    this.tipoEquipamento,
    this.btu,
    this.evaporadora,
    this.condensadora,
    this.localizacao,
    this.observacoes,
    this.tarefas = const [],
    this.checklist,
  });

  bool get isFinalizado => status == 'FINALIZADO';
  bool get isEmAndamento => status == 'EM_ANDAMENTO';

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    var rawTarefas = json['tarefas'];
    List<TaskModel> tarefasList = [];
    if (rawTarefas is List) {
      tarefasList = rawTarefas
          .whereType<Map<String, dynamic>>()
          .map((t) => TaskModel.fromJson(t))
          .toList();
    }

    String? tipo;
    if (json['tipo_equipamento'] is Map) {
      tipo = json['tipo_equipamento']['nome'] as String?;
    } else if (json['tipo_equipamento'] is String) {
      tipo = json['tipo_equipamento'] as String;
    }

    return EquipmentModel(
      id: json['id'] as int? ?? 0,
      equipamentoId: json['equipamento_id'] as int?,
      tag: json['tag'] as String?,
      isGeneric: json['is_generic'] as bool? ?? false,
      registroPendente: json['registro_pendente'] as bool? ?? false,
      checklistPendente: json['checklist_pendente'] as bool? ?? true,
      cadastrado: json['cadastrado'] as bool? ?? false,
      status: json['status'] as String? ?? 'AGUARDANDO',
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      tipoEquipamento: tipo,
      btu: json['btu']?.toString(),
      evaporadora: json['evaporadora'] as String?,
      condensadora: json['condensadora'] as String?,
      localizacao: json['localizacao'] as String?,
      observacoes: json['observacoes'] as String?,
      tarefas: tarefasList,
      checklist: json['checklist'] != null && json['checklist'] is Map<String, dynamic>
          ? ChecklistModel.fromJson(json['checklist'] as Map<String, dynamic>)
          : null,
    );
  }
}
