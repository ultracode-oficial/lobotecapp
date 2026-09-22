import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/checklist_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EquipmentChecklistScreen extends StatefulWidget {
  final int etapaId;
  final int equipmentId;
  final ChecklistModel? checklist;

  const EquipmentChecklistScreen({
    super.key,
    required this.etapaId,
    required this.equipmentId,
    this.checklist,
  });

  @override
  State<EquipmentChecklistScreen> createState() =>
      _EquipmentChecklistScreenState();
}

class _EquipmentChecklistScreenState extends State<EquipmentChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? _photoBeforePath;
  String? _photoAfterPath;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _estimatedTimeController =
      TextEditingController();

  String _selectedStatus = 'OK'; // 'OK' ou 'PROBLEMA_IDENTIFICADO'

  @override
  void initState() {
    super.initState();
    final cl = widget.checklist;
    if (cl != null) {
      _selectedStatus = cl.statusEquipamento ?? 'OK';
      _tempController.text = cl.temperatura ?? '';
      _obsController.text = cl.observacoes ?? '';
      _problemController.text = cl.problema ?? '';
      _solutionController.text = cl.solucao ?? '';
      _materialController.text = cl.material ?? '';
      _estimatedTimeController.text = cl.tempoResolucao ?? '';
      _photoBeforePath = cl.fotoAntesUrl;
      _photoAfterPath = cl.fotoDepoisUrl;
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _obsController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _materialController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(String tipo) async {
    try {
      final XFile? picked = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto com a Câmera'),
                onTap: () async {
                  final file =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () async {
                  final file =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
            ],
          ),
        ),
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final dataSource = getIt<ExecutionRemoteDataSource>();
      await dataSource.uploadChecklistPhoto(
        widget.etapaId,
        widget.equipmentId,
        tipo: tipo,
        imagePath: picked.path,
      );

      if (mounted) {
        setState(() {
          if (tipo == 'antes') {
            _photoBeforePath = picked.path;
          } else {
            _photoAfterPath = picked.path;
          }
          _isUploadingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto "$tipo" enviada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveChecklist() async {
    if (_selectedStatus == 'PROBLEMA_IDENTIFICADO' &&
        _problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o problema identificado.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'status_equipamento': _selectedStatus,
        'temperatura': _tempController.text.trim(),
        'observacoes': _obsController.text.trim(),
      };

      if (_selectedStatus == 'PROBLEMA_IDENTIFICADO') {
        data['problema'] = _problemController.text.trim();
        data['solucao'] = _solutionController.text.trim();
        data['material'] = _materialController.text.trim();
        data['tempo_resolucao'] = _estimatedTimeController.text.trim();
      }

      final dataSource = getIt<ExecutionRemoteDataSource>();
      await dataSource.saveChecklist(
        widget.etapaId,
        widget.equipmentId,
        data,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checklist salvo com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar checklist: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCorrectiveFields = _selectedStatus == 'PROBLEMA_IDENTIFICADO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preencher Checklist'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EQUIPAMENTO #${widget.equipmentId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),

                // Fotos Antes
                const Text(
                  'Fotos Antes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPhotoBox(
                  tipo: 'antes',
                  path: _photoBeforePath,
                  onTap: () => _pickAndUploadPhoto('antes'),
                ),
                const SizedBox(height: 16),

                // Fotos Depois
                const Text(
                  'Fotos Depois',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPhotoBox(
                  tipo: 'depois',
                  path: _photoAfterPath,
                  onTap: () => _pickAndUploadPhoto('depois'),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  label: 'Temperatura Aferida (°C)',
                  hint: 'Ex: 18.5',
                  controller: _tempController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Condição do Equipamento *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Normal (OK)')),
                        selected: _selectedStatus == 'OK',
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _selectedStatus == 'OK'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedStatus = 'OK');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Necessita Corretiva')),
                        selected: _selectedStatus == 'PROBLEMA_IDENTIFICADO',
                        selectedColor: AppColors.error.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: _selectedStatus == 'PROBLEMA_IDENTIFICADO'
                              ? AppColors.error
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                                () => _selectedStatus = 'PROBLEMA_IDENTIFICADO');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (showCorrectiveFields) ...[
                  CustomTextField(
                    label: 'Problema Identificado *',
                    hint: 'Descreva a falha ou anomalia...',
                    controller: _problemController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Solução Recomendada',
                    hint: 'Descreva a ação recomendada...',
                    controller: _solutionController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Material Necessário',
                    hint: 'Gás, capacitor, placa...',
                    controller: _materialController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Tempo Estimado de Resolução',
                    hint: 'Ex: 2 horas',
                    controller: _estimatedTimeController,
                  ),
                  const SizedBox(height: 20),
                ],

                CustomTextField(
                  label: 'Observações Gerais',
                  hint: 'Comentários técnicos adicionais...',
                  controller: _obsController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: _isSaving ? 'SALVANDO...' : 'SALVAR CHECKLIST',
                  onPressed: _isSaving ? null : () => _saveChecklist(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBox({
    required String tipo,
    required String? path,
    required VoidCallback onTap,
  }) {
    final hasImage = path != null && path.isNotEmpty;

    return GestureDetector(
      onTap: _isUploadingPhoto ? null : onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppColors.success : AppColors.border,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? (path.startsWith('http')
                ? Image.network(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 32, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      'Tirar foto $tipo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
