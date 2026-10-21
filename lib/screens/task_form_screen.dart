import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../core/constants/api_constants.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';

class _FormOption {
  final int id;
  final String label;
  final String? valueCode;
  final int order;

  _FormOption({
    required this.id,
    required this.label,
    this.valueCode,
    required this.order,
  });

  factory _FormOption.fromJson(Map<String, dynamic> json) {
    return _FormOption(
      id: int.tryParse('${json['id']}') ?? 0,
      label: json['label']?.toString() ?? 'Opção',
      valueCode: json['value_code']?.toString(),
      order: int.tryParse('${json['order']}') ?? 0,
    );
  }
}

class _FormAttachment {
  final int id;
  final int respostaId;
  final String filePath;
  final String? originalName;

  _FormAttachment({
    required this.id,
    required this.respostaId,
    required this.filePath,
    this.originalName,
  });

  factory _FormAttachment.fromJson(Map<String, dynamic> json, int respostaId) {
    return _FormAttachment(
      id: int.tryParse('${json['id']}') ?? 0,
      respostaId: respostaId,
      filePath: json['file_path']?.toString() ?? json['url']?.toString() ?? '',
      originalName: json['original_name']?.toString(),
    );
  }
}

class _FormQuestion {
  final int id;
  final int formularioVersaoId;
  final String type; // text, number, checkbox, radio, select, date, time, datetime, range, file, image
  final String title;
  final String? description;
  final String? placeholder;
  final bool isRequired;
  final int order;
  final Map<String, dynamic>? config;
  final List<_FormOption> options;

  _FormQuestion({
    required this.id,
    required this.formularioVersaoId,
    required this.type,
    required this.title,
    this.description,
    this.placeholder,
    required this.isRequired,
    required this.order,
    this.config,
    required this.options,
  });

  factory _FormQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final optionsList = <_FormOption>[];
    if (rawOptions is List) {
      for (final opt in rawOptions.whereType<Map>()) {
        optionsList.add(_FormOption.fromJson(Map<String, dynamic>.from(opt)));
      }
      optionsList.sort((a, b) => a.order.compareTo(b.order));
    }

    return _FormQuestion(
      id: int.tryParse('${json['id']}') ?? 0,
      formularioVersaoId: int.tryParse('${json['formulario_versao_id']}') ?? 0,
      type: (json['type']?.toString() ?? 'text').toLowerCase(),
      title: json['title']?.toString() ?? 'Pergunta',
      description: json['description']?.toString(),
      placeholder: json['placeholder']?.toString(),
      isRequired: json['is_required'] == true ||
          json['is_required'] == 1 ||
          json['is_required'] == '1',
      order: int.tryParse('${json['order']}') ?? 0,
      config: json['config'] is Map ? Map<String, dynamic>.from(json['config']) : null,
      options: optionsList,
    );
  }
}

class TaskFormScreen extends StatefulWidget {
  final int tarefaId;
  final String tarefaNome;

  const TaskFormScreen({
    super.key,
    required this.tarefaId,
    required this.tarefaNome,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _ds = getIt<ExecutionRemoteDataSource>();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _noForm = false;

  int? _versaoId;
  String? _envioStatus;

  List<_FormQuestion> _questions = [];

  // Mapeamentos de respostas
  final Map<int, int> _perguntaToRespostaId = {}; // perguntaId -> respostaId
  final Map<int, TextEditingController> _textControllers = {};
  final Map<int, double> _rangeValues = {};
  final Map<int, DateTime> _dateTimeValues = {};
  final Map<int, int> _selectedSingleOption = {}; // radio ou select
  final Map<int, Set<int>> _selectedMultiOptions = {}; // checkbox
  final Map<int, List<_FormAttachment>> _attachments = {}; // file ou image
  final Set<int> _uploadingQuestions = {};

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _dioMessage(Object e) {
    if (e is DioException) {
      final body = e.response?.data;
      if (body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (body['message'] != null) return body['message'].toString();
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _ds.getTaskForm(widget.tarefaId);

      _versaoId = int.tryParse('${data['formulario_versao_id']}');
      _envioStatus = data['status']?.toString();

      final rawQuestions = data['perguntas'];
      final qs = <_FormQuestion>[];
      if (rawQuestions is List) {
        for (final q in rawQuestions.whereType<Map>()) {
          qs.add(_FormQuestion.fromJson(Map<String, dynamic>.from(q)));
        }
        qs.sort((a, b) => a.order.compareTo(b.order));
      }
      _questions = qs;

      _parseExistingAnswers(data['respostas_existentes']);

      if (!mounted) return;
      setState(() => _loading = false);
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 404) {
        setState(() {
          _noForm = true;
          _loading = false;
        });
      } else {
        setState(() {
          _error = _dioMessage(e);
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _dioMessage(e);
        _loading = false;
      });
    }
  }

  void _parseExistingAnswers(dynamic rawAnswers) {
    if (rawAnswers is! List) return;

    for (final raw in rawAnswers.whereType<Map>()) {
      final r = Map<String, dynamic>.from(raw);
      final respostaId = int.tryParse('${r['id']}');
      final perguntaId = int.tryParse('${r['formulario_pergunta_id']}');

      if (perguntaId == null) continue;
      if (respostaId != null) {
        _perguntaToRespostaId[perguntaId] = respostaId;
      }

      // Encontra a pergunta correspondente
      final qList = _questions.where((q) => q.id == perguntaId);
      if (qList.isEmpty) continue;
      final q = qList.first;

      switch (q.type) {
        case 'text':
          final val = r['value_text']?.toString() ?? '';
          _textControllers[perguntaId] = TextEditingController(text: val);
          break;

        case 'number':
          final val = r['value_number']?.toString() ?? '';
          _textControllers[perguntaId] = TextEditingController(text: val);
          break;

        case 'range':
          final val = double.tryParse('${r['value_number']}');
          if (val != null) {
            _rangeValues[perguntaId] = val;
          } else {
            final min = double.tryParse('${q.config?['min']}') ?? 0.0;
            _rangeValues[perguntaId] = min;
          }
          break;

        case 'date':
        case 'time':
        case 'datetime':
          final rawDt = r['value_datetime']?.toString();
          if (rawDt != null && rawDt.isNotEmpty) {
            final dt = DateTime.tryParse(rawDt);
            if (dt != null) _dateTimeValues[perguntaId] = dt.toLocal();
          }
          break;

        case 'radio':
        case 'select':
          final optId = int.tryParse('${r['selected_option_id']}');
          if (optId != null) {
            _selectedSingleOption[perguntaId] = optId;
          }
          break;

        case 'checkbox':
          final rawMulti = r['multiple_options'];
          final set = <int>{};
          if (rawMulti is List) {
            for (final m in rawMulti) {
              if (m is Map) {
                final optId = int.tryParse('${m['formulario_pergunta_option_id']}');
                if (optId != null) set.add(optId);
              } else if (m is num) {
                set.add(m.toInt());
              }
            }
          }
          _selectedMultiOptions[perguntaId] = set;
          break;

        case 'file':
        case 'image':
          final rawAnexos = r['anexos'];
          final list = <_FormAttachment>[];
          if (rawAnexos is List && respostaId != null) {
            for (final a in rawAnexos.whereType<Map>()) {
              list.add(_FormAttachment.fromJson(Map<String, dynamic>.from(a), respostaId));
            }
          }
          _attachments[perguntaId] = list;
          break;
      }
    }

    // Inicializa campos sem resposta prévia
    for (final q in _questions) {
      if (q.type == 'text' || q.type == 'number') {
        _textControllers.putIfAbsent(q.id, () => TextEditingController());
      } else if (q.type == 'range') {
        final min = double.tryParse('${q.config?['min']}') ?? 0.0;
        _rangeValues.putIfAbsent(q.id, () => min);
      } else if (q.type == 'checkbox') {
        _selectedMultiOptions.putIfAbsent(q.id, () => <int>{});
      } else if (q.type == 'file' || q.type == 'image') {
        _attachments.putIfAbsent(q.id, () => <_FormAttachment>[]);
      }
    }
  }

  bool _isQuestionAnswered(_FormQuestion q) {
    switch (q.type) {
      case 'text':
      case 'number':
        return (_textControllers[q.id]?.text.trim() ?? '').isNotEmpty;
      case 'range':
        return _rangeValues.containsKey(q.id);
      case 'date':
      case 'time':
      case 'datetime':
        return _dateTimeValues.containsKey(q.id);
      case 'radio':
      case 'select':
        return _selectedSingleOption.containsKey(q.id);
      case 'checkbox':
        return (_selectedMultiOptions[q.id] ?? {}).isNotEmpty;
      case 'file':
      case 'image':
        return (_attachments[q.id] ?? []).isNotEmpty;
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _buildAnswersPayload() {
    final answers = <Map<String, dynamic>>[];

    for (final q in _questions) {
      // file e image são gerenciados via upload de anexo e não precisam de value no payload
      if (q.type == 'file' || q.type == 'image') continue;

      if (!_isQuestionAnswered(q)) continue;

      final map = <String, dynamic>{
        'formulario_pergunta_id': q.id,
      };

      switch (q.type) {
        case 'text':
          map['value_text'] = _textControllers[q.id]!.text.trim();
          break;

        case 'number':
          final rawVal = _textControllers[q.id]!.text.trim().replaceAll(',', '.');
          final n = num.tryParse(rawVal);
          if (n != null) map['value_number'] = n;
          break;

        case 'range':
          map['value_number'] = _rangeValues[q.id] ?? 0.0;
          break;

        case 'date':
        case 'time':
        case 'datetime':
          final dt = _dateTimeValues[q.id];
          if (dt != null) map['value_datetime'] = dt.toUtc().toIso8601String();
          break;

        case 'radio':
        case 'select':
          final optId = _selectedSingleOption[q.id];
          if (optId != null) map['selected_option_id'] = optId;
          break;

        case 'checkbox':
          final selected = _selectedMultiOptions[q.id] ?? {};
          if (selected.isNotEmpty) {
            map['multiple_options'] = selected.toList();
          }
          break;
      }

      answers.add(map);
    }

    return answers;
  }

  Future<void> _submitForm(String status) async {
    final versao = _versaoId;
    if (versao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versão do formulário não identificada.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Se estiver enviando definitivamente (ENVIADO), valida campos obrigatórios
    if (status == 'ENVIADO') {
      for (final q in _questions) {
        if (q.isRequired && !_isQuestionAnswered(q)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Por favor, preencha: ${q.title}'),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }
      }
    }

    setState(() => _saving = true);

    try {
      final answers = _buildAnswersPayload();

      await _ds.submitTaskForm(
        widget.tarefaId,
        formularioVersaoId: versao,
        status: status,
        respostas: answers,
      );

      // Conforme a documentação:
      // "ENVIADO only marks the envio. The tarefa stays PENDENTE.
      // Mark it done with PATCH /api/executar/tarefas/{tarefa}/toggle-status and { status: FEITO }"
      if (status == 'ENVIADO') {
        try {
          await _ds.toggleTask(widget.tarefaId, status: 'FEITO');
        } catch (e) {
          debugPrint('Aviso ao concluir tarefa após formulário: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ENVIADO'
                ? 'Formulário enviado e tarefa concluída com sucesso!'
                : 'Rascunho salvo com sucesso!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, status == 'ENVIADO');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar formulário: ${_dioMessage(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _concluirSemFormulario() async {
    setState(() => _saving = true);
    try {
      await _ds.toggleTask(widget.tarefaId, status: 'FEITO');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarefa marcada como concluída!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao concluir tarefa: ${_dioMessage(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickAndUploadAttachment(_FormQuestion q, {required ImageSource source}) async {
    final respostaId = _perguntaToRespostaId[q.id];
    if (respostaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro de resposta não encontrado para esta pergunta.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (file == null) return;

    setState(() => _uploadingQuestions.add(q.id));

    try {
      final res = await _ds.uploadFormAttachment(respostaId, file.path);
      final rawData = res['data'] ?? res;

      final attachment = _FormAttachment(
        id: int.tryParse('${rawData['id']}') ?? DateTime.now().millisecondsSinceEpoch,
        respostaId: respostaId,
        filePath: rawData['file_path']?.toString() ?? rawData['url']?.toString() ?? file.path,
        originalName: rawData['original_name']?.toString() ?? file.name,
      );

      setState(() {
        _attachments.putIfAbsent(q.id, () => <_FormAttachment>[]).add(attachment);
        _uploadingQuestions.remove(q.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anexo enviado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingQuestions.remove(q.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar anexo: ${_dioMessage(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImagePreview(String imagePath) {
    final url = ApiConstants.resolveStorageUrl(imagePath);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: const Text('Não foi possível carregar a imagem.'),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(_FormQuestion q) async {
    final current = _dateTimeValues[q.id] ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    if (q.type == 'datetime') {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (time == null || !mounted) return;

      setState(() {
        _dateTimeValues[q.id] = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    } else {
      setState(() {
        _dateTimeValues[q.id] = DateTime(date.year, date.month, date.day);
      });
    }
  }

  Future<void> _pickTime(_FormQuestion q) async {
    final current = _dateTimeValues[q.id] ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    setState(() {
      _dateTimeValues[q.id] = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt, String type) {
    String p(int n) => n.toString().padLeft(2, '0');
    if (type == 'date') {
      return '${p(dt.day)}/${p(dt.month)}/${dt.year}';
    } else if (type == 'time') {
      return '${p(dt.hour)}:${p(dt.minute)}';
    }
    return '${p(dt.day)}/${p(dt.month)}/${dt.year} ${p(dt.hour)}:${p(dt.minute)}';
  }

  Widget _buildQuestionField(_FormQuestion q) {
    switch (q.type) {
      case 'text':
        return TextField(
          controller: _textControllers[q.id],
          maxLines: 3,
          decoration: InputDecoration(
            hintText: q.placeholder ?? 'Digite aqui...',
            border: const OutlineInputBorder(),
          ),
        );

      case 'number':
        final unit = q.config?['unit']?.toString();
        return TextField(
          controller: _textControllers[q.id],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: q.placeholder ?? '0.00',
            suffixText: unit != null && unit.isNotEmpty ? unit : null,
            border: const OutlineInputBorder(),
          ),
        );

      case 'range':
        final min = double.tryParse('${q.config?['min']}') ?? 0.0;
        final max = double.tryParse('${q.config?['max']}') ?? 100.0;
        final step = double.tryParse('${q.config?['step']}');
        final unit = q.config?['unit']?.toString() ?? '';
        final val = (_rangeValues[q.id] ?? min).clamp(min, max);

        int? divisions;
        if (step != null && step > 0) {
          divisions = ((max - min) / step).round();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${q.config?['min_label'] ?? min} $unit',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  '${val.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${q.config?['max_label'] ?? max} $unit',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            Slider(
              value: val,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: AppColors.primary,
              label: '${val.toStringAsFixed(1)} $unit',
              onChanged: (newVal) => setState(() => _rangeValues[q.id] = newVal),
            ),
          ],
        );

      case 'date':
      case 'time':
      case 'datetime':
        final dt = _dateTimeValues[q.id];
        final label = dt != null
            ? _formatDateTime(dt, q.type)
            : (q.type == 'date'
                ? 'Selecionar data'
                : q.type == 'time'
                    ? 'Selecionar hora'
                    : 'Selecionar data e hora');

        return OutlinedButton.icon(
          onPressed: () => q.type == 'time' ? _pickTime(q) : _pickDate(q),
          icon: Icon(
            q.type == 'time' ? Icons.access_time : Icons.calendar_today,
            color: AppColors.primary,
          ),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignment: Alignment.centerLeft,
          ),
        );

      case 'select':
        return DropdownButtonFormField<int>(
          initialValue: _selectedSingleOption[q.id],
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          hint: Text(q.placeholder ?? 'Selecione uma opção'),
          items: q.options
              .map((o) => DropdownMenuItem<int>(
                    value: o.id,
                    child: Text(o.label),
                  ))
              .toList(),
          onChanged: (val) => setState(() {
            if (val != null) _selectedSingleOption[q.id] = val;
          }),
        );

      case 'radio':
        return RadioGroup<int>(
          groupValue: _selectedSingleOption[q.id],
          onChanged: (val) => setState(() {
            if (val != null) _selectedSingleOption[q.id] = val;
          }),
          child: Column(
            children: q.options
                .map((o) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(o.label),
                      value: o.id,
                    ))
                .toList(),
          ),
        );

      case 'checkbox':
        final selectedSet = _selectedMultiOptions[q.id] ?? {};
        return Column(
          children: q.options
              .map((o) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(o.label),
                    value: selectedSet.contains(o.id),
                    onChanged: (checked) => setState(() {
                      final set = _selectedMultiOptions.putIfAbsent(q.id, () => <int>{});
                      if (checked == true) {
                        set.add(o.id);
                      } else {
                        set.remove(o.id);
                      }
                    }),
                  ))
              .toList(),
        );

      case 'image':
      case 'file':
        final attachments = _attachments[q.id] ?? [];
        final isUploading = _uploadingQuestions.contains(q.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachments.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map((att) {
                  final url = ApiConstants.resolveStorageUrl(att.filePath);

                  return GestureDetector(
                    onTap: () => _showImagePreview(att.filePath),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: Image.network(
                              url,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.insert_drive_file,
                                color: AppColors.primary,
                                size: 36,
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Text(
                              att.originalName ?? 'Anexo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (isUploading) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Enviando anexo...', style: TextStyle(fontSize: 13)),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadAttachment(q, source: ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Câmera'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickAndUploadAttachment(q, source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Galeria'),
                  ),
                ],
              ),
            ],
          ],
        );

      default:
        return TextField(
          controller: _textControllers[q.id],
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
    }
  }

  Widget _buildQuestionCard(_FormQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.isRequired ? '${q.title} *' : q.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (q.description != null && q.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              q.description!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          _buildQuestionField(q),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.tarefaNome),
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_noForm) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 54, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Sem formulário vinculado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta tarefa não possui formulário obrigatório. Você pode marcá-la como concluída diretamente.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_saving)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _concluirSemFormulario,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Concluir Tarefa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar para o Aparelho'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadForm,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('Formulário sem perguntas configuradas.'));
    }

    return Column(
      children: [
        if (_envioStatus != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _envioStatus == 'ENVIADO'
                ? AppColors.success.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            child: Text(
              _envioStatus == 'ENVIADO'
                  ? 'Formulário já enviado anteriormente'
                  : 'Rascunho em edição',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _envioStatus == 'ENVIADO' ? AppColors.success : AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _questions.map(_buildQuestionCard).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _submitForm('RASCUNHO'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Salvar rascunho'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : () => _submitForm('ENVIADO'),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enviar e Concluir',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
