class ChecklistPhoto {
  final int? id;
  final String url;
  final String? path;
  final int sortOrder;

  const ChecklistPhoto({
    this.id,
    required this.url,
    this.path,
    this.sortOrder = 0,
  });

  factory ChecklistPhoto.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] ?? json['path'] ?? '').toString();
    return ChecklistPhoto(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      url: url,
      path: json['path']?.toString(),
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
    );
  }
}

class ChecklistModel {
  static const int maxFotosPorTipo = 10;

  final String statusChecklist;
  final String? statusEquipamento;
  final String? problema;
  final String? solucao;
  final String? material;
  final String? tempoResolucao;
  final String? temperatura;
  final String? observacoes;
  final List<ChecklistPhoto> fotosAntes;
  final List<ChecklistPhoto> fotosDepois;

  ChecklistModel({
    required this.statusChecklist,
    this.statusEquipamento,
    this.problema,
    this.solucao,
    this.material,
    this.tempoResolucao,
    this.temperatura,
    this.observacoes,
    this.fotosAntes = const [],
    this.fotosDepois = const [],
  });

  bool get isPreenchido => statusChecklist == 'PREENCHIDO';
  bool get hasProblema => statusEquipamento == 'PROBLEMA_IDENTIFICADO';

  /// Compat: primeira foto antes (legado single-url).
  String? get fotoAntesUrl =>
      fotosAntes.isNotEmpty ? fotosAntes.first.url : null;

  /// Compat: primeira foto depois (legado single-url).
  String? get fotoDepoisUrl =>
      fotosDepois.isNotEmpty ? fotosDepois.first.url : null;

  bool get hasFotoAntes => fotosAntes.isNotEmpty;
  bool get hasFotoDepois => fotosDepois.isNotEmpty;

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
      fotosAntes: _readPhotos(json, 'antes'),
      fotosDepois: _readPhotos(json, 'depois'),
    );
  }

  /// Lê arrays (`fotos_antes`) e cai no legado single (`foto_antes_url`).
  static List<ChecklistPhoto> _readPhotos(
    Map<String, dynamic> json,
    String tipo,
  ) {
    ChecklistPhoto? fromDynamic(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) {
        return ChecklistPhoto(url: v);
      }
      if (v is Map) {
        final map = Map<String, dynamic>.from(v);
        final url = (map['url'] ?? map['path'] ?? '').toString();
        if (url.isEmpty) return null;
        return ChecklistPhoto.fromJson(map);
      }
      return null;
    }

    final listKey = json['fotos_$tipo'];
    if (listKey is List && listKey.isNotEmpty) {
      return listKey
          .map(fromDynamic)
          .whereType<ChecklistPhoto>()
          .toList();
    }

    final nested = json['fotos'];
    if (nested is Map && nested[tipo] is List) {
      return (nested[tipo] as List)
          .map(fromDynamic)
          .whereType<ChecklistPhoto>()
          .toList();
    }

    final single = fromDynamic(json['foto_${tipo}_url']) ??
        fromDynamic(json['foto_$tipo']) ??
        fromDynamic(json['foto_${tipo}_path']);

    return single != null ? [single] : const [];
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
