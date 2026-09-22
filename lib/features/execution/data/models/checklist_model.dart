class ChecklistModel {
  final String statusChecklist;
  final String? statusEquipamento;
  final String? problema;
  final String? solucao;
  final String? material;
  final String? tempoResolucao;
  final String? temperatura;
  final String? observacoes;
  final String? fotoAntesUrl;
  final String? fotoDepoisUrl;

  ChecklistModel({
    required this.statusChecklist,
    this.statusEquipamento,
    this.problema,
    this.solucao,
    this.material,
    this.tempoResolucao,
    this.temperatura,
    this.observacoes,
    this.fotoAntesUrl,
    this.fotoDepoisUrl,
  });

  bool get isPreenchido => statusChecklist == 'PREENCHIDO';
  bool get hasProblema => statusEquipamento == 'PROBLEMA_IDENTIFICADO';

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    }
    return ChecklistModel(
      statusChecklist: json['status_checklist'] as String? ?? 'PENDENTE',
      statusEquipamento: json['status_equipamento'] as String?,
      problema: json['problema'] as String?,
      solucao: json['solucao'] as String?,
      material: json['material'] as String?,
      tempoResolucao: json['tempo_resolucao']?.toString(),
      temperatura: json['temperatura']?.toString(),
      observacoes: json['observacoes'] as String?,
      fotoAntesUrl: json['foto_antes_url'] as String? ?? json['foto_antes'] as String?,
      fotoDepoisUrl: json['foto_depois_url'] as String? ?? json['foto_depois'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_equipamento': statusEquipamento ?? 'OK',
      if (problema != null) 'problema': problema,
      if (solucao != null) 'solucao': solucao,
      if (material != null) 'material': material,
      if (tempoResolucao != null) 'tempo_resolucao': tempoResolucao,
      if (temperatura != null) 'temperatura': temperatura,
      if (observacoes != null) 'observacoes': observacoes,
    };
  }
}
