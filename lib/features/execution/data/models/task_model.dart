bool _toBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val == 1 || val == '1' || val == 'true') return true;
  return false;
}

int? _toInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

class TaskModel {
  final int id;
  final String nome;
  final String status;
  final bool temFormulario;
  final String? formularioStatus;

  TaskModel({
    required this.id,
    required this.nome,
    required this.status,
    this.temFormulario = false,
    this.formularioStatus,
  });

  bool get isFeito => status == 'FEITO';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }
    String? extractedName;
    if (json['nome'] != null) {
      extractedName = json['nome']?.toString();
    } else if (json['name'] != null) {
      extractedName = json['name']?.toString();
    } else if (json['titulo'] != null) {
      extractedName = json['titulo']?.toString();
    } else if (json['tipo_tarefa'] is Map) {
      final tipo = json['tipo_tarefa'] as Map;
      extractedName = tipo['name']?.toString() ??
          tipo['nome']?.toString() ??
          tipo['titulo']?.toString();
    }

    return TaskModel(
      id: _toInt(json['id']) ?? 0,
      nome: extractedName ?? 'Tarefa',
      status: json['status']?.toString() ?? 'PENDENTE',
      temFormulario: _toBool(json['tem_formulario']),
      formularioStatus: json['formulario_status']?.toString(),
    );
  }
}
