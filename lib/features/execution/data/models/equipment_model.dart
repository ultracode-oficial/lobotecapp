import 'checklist_model.dart';
import 'task_model.dart';

bool _toBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val == 1 || val == '1' || val == 'true') return true;
  if (val == 0 || val == '0' || val == 'false') return false;
  return defaultValue;
}

int? _toInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

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
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }
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
      tipo = json['tipo_equipamento']['name']?.toString() ??
          json['tipo_equipamento']['nome']?.toString();
    } else if (json['tipo_equipamento'] is String) {
      tipo = json['tipo_equipamento'] as String;
    }


    return EquipmentModel(
      id: _toInt(json['id']) ?? 0,
      equipamentoId: _toInt(json['equipamento_id']),
      tag: json['tag']?.toString(),
      isGeneric: _toBool(json['is_generic'], defaultValue: false),
      registroPendente: _toBool(json['registro_pendente'], defaultValue: false),
      checklistPendente: _toBool(json['checklist_pendente'], defaultValue: true),
      cadastrado: _toBool(json['cadastrado'], defaultValue: false),
      status: json['status']?.toString() ?? 'AGUARDANDO',
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      tipoEquipamento: tipo,
      btu: json['btu']?.toString(),
      evaporadora: json['evaporadora']?.toString(),
      condensadora: json['condensadora']?.toString(),
      localizacao: json['localizacao']?.toString(),
      observacoes: json['observacoes']?.toString(),
      tarefas: tarefasList,
      checklist: json['checklist'] != null && json['checklist'] is Map<String, dynamic>
          ? ChecklistModel.fromJson(json['checklist'] as Map<String, dynamic>)
          : null,
    );
  }
}
