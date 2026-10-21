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
      fotoAntesUrl: _readPhoto(json, 'antes'),
      fotoDepoisUrl: _readPhoto(json, 'depois'),
    );
  }

  /// Procura a foto em formatos possíveis: foto_antes_url, foto_antes,
  /// foto_antes_path, fotos_antes (lista) e fotos: {antes: ...}.
  static String? _readPhoto(Map<String, dynamic> json, String tipo) {
    String? pick(dynamic v) {
      if (v is String && v.isNotEmpty) return v;
      if (v is List && v.isNotEmpty) return pick(v.first);
      if (v is Map) return pick(v['url'] ?? v['path']);
      return null;
    }

    return pick(json['foto_${tipo}_url']) ??
        pick(json['foto_$tipo']) ??
        pick(json['foto_${tipo}_path']) ??
        pick(json['fotos_$tipo']) ??
        (json['fotos'] is Map ? pick((json['fotos'] as Map)[tipo]) : null);
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
