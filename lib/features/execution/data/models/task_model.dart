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
    return TaskModel(
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ??
          json['titulo'] as String? ??
          (json['tipo_tarefa'] is Map ? json['tipo_tarefa']['nome'] as String? : null) ??
          'Tarefa',
      status: json['status'] as String? ?? 'PENDENTE',
      temFormulario: json['tem_formulario'] as bool? ?? false,
      formularioStatus: json['formulario_status'] as String?,
    );
  }
}
