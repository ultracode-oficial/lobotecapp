import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../core/constants/api_constants.dart';
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

  List<ChecklistPhoto> _fotosAntes = [];
  List<ChecklistPhoto> _fotosDepois = [];
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
      _fotosAntes = List<ChecklistPhoto>.from(cl.fotosAntes);
      _fotosDepois = List<ChecklistPhoto>.from(cl.fotosDepois);
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

  List<ChecklistPhoto> _fotosOf(String tipo) =>
      tipo == 'antes' ? _fotosAntes : _fotosDepois;

  Future<void> _pickAndUploadPhoto(String tipo) async {
    if (_fotosOf(tipo).length >= ChecklistModel.maxFotosPorTipo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Limite de ${ChecklistModel.maxFotosPorTipo} fotos atingido.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

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
      final res = await dataSource.uploadChecklistPhoto(
        widget.etapaId,
        widget.equipmentId,
        tipo: tipo,
        imagePath: picked.path,
      );

      final returnedUrl = res['url']?.toString() ??
          res['path']?.toString() ??
          picked.path;

      if (mounted) {
        setState(() {
          final photo = ChecklistPhoto(
            id: res['id'] is int
                ? res['id'] as int
                : int.tryParse(res['id']?.toString() ?? ''),
            url: returnedUrl,
            path: res['path']?.toString(),
            sortOrder: res['sort_order'] is int
                ? res['sort_order'] as int
                : _fotosOf(tipo).length,
          );
          if (tipo == 'antes') {
            _fotosAntes = [..._fotosAntes, photo];
          } else {
            _fotosDepois = [..._fotosDepois, photo];
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

  Future<void> _deletePhoto(String tipo, ChecklistPhoto photo) async {
    if (photo.id == null) {
      setState(() {
        if (tipo == 'antes') {
          _fotosAntes = _fotosAntes.where((p) => p != photo).toList();
        } else {
          _fotosDepois = _fotosDepois.where((p) => p != photo).toList();
        }
      });
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      await getIt<ExecutionRemoteDataSource>().deleteChecklistPhoto(
        widget.etapaId,
        widget.equipmentId,
        photo.id!,
      );
      if (!mounted) return;
      setState(() {
        if (tipo == 'antes') {
          _fotosAntes = _fotosAntes.where((p) => p.id != photo.id).toList();
        } else {
          _fotosDepois = _fotosDepois.where((p) => p.id != photo.id).toList();
        }
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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

                _buildPhotoGallerySection(
                  label: 'Fotos Antes',
                  tipo: 'antes',
                  fotos: _fotosAntes,
                ),
                const SizedBox(height: 16),
                _buildPhotoGallerySection(
                  label: 'Fotos Depois',
                  tipo: 'depois',
                  fotos: _fotosDepois,
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

  Widget _buildPhotoImage(String path) {
    Widget broken() => const Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
        );

    if (!path.startsWith('http') && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, _, _) => broken());
    }

    final url = ApiConstants.resolveStorageUrl(path);
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => broken());
  }

  Widget _buildPhotoGallerySection({
    required String label,
    required String tipo,
    required List<ChecklistPhoto> fotos,
  }) {
    final canAdd = fotos.length < ChecklistModel.maxFotosPorTipo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${fotos.length}/${ChecklistModel.maxFotosPorTipo})',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (fotos.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final photo = fotos[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: _buildPhotoImage(photo.url),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Material(
                        color: Colors.black87,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isUploadingPhoto
                              ? null
                              : () => _deletePhoto(tipo, photo),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (fotos.isNotEmpty) const SizedBox(height: 8),
        if (_isUploadingPhoto)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (canAdd)
          OutlinedButton.icon(
            onPressed: () => _pickAndUploadPhoto(tipo),
            icon: const Icon(Icons.add_a_photo, size: 18),
            label: Text(fotos.isEmpty ? 'Adicionar foto' : 'Adicionar outra'),
          ),
      ],
    );
  }
}
