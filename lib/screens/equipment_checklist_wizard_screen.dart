import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/colors.dart';
import '../core/constants/api_constants.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/checklist_model.dart';
import '../widgets/custom_button.dart';

enum ChecklistWizardMode {
  inicial, // Vistoria de entrada: Condição, Foto Antes, Temperatura inicial
  finalizacao, // Vistoria de saída: Foto Depois, Temperatura final, Conclusão
}

class EquipmentChecklistWizardScreen extends StatefulWidget {
  final int etapaId;
  final int equipmentId;
  final ChecklistModel? checklist;
  final ChecklistWizardMode mode;

  const EquipmentChecklistWizardScreen({
    super.key,
    required this.etapaId,
    required this.equipmentId,
    this.checklist,
    this.mode = ChecklistWizardMode.inicial,
  });

  @override
  State<EquipmentChecklistWizardScreen> createState() =>
      _EquipmentChecklistWizardScreenState();
}

class _EquipmentChecklistWizardScreenState
    extends State<EquipmentChecklistWizardScreen> {
  final _ds = getIt<ExecutionRemoteDataSource>();
  final _picker = ImagePicker();
  final _pageController = PageController();

  int _currentPage = 0;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  // Campos do checklist
  String _statusEquipamento = 'OK'; // 'OK' ou 'PROBLEMA_IDENTIFICADO'
  String? _fotoAntesUrl;
  String? _fotoDepoisUrl;
  final _tempController = TextEditingController();
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _materialController = TextEditingController();
  final _obsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cl = widget.checklist;
    if (cl != null) {
      _statusEquipamento = cl.statusEquipamento ?? 'OK';
      _fotoAntesUrl = cl.fotoAntesUrl;
      _fotoDepoisUrl = cl.fotoDepoisUrl;
      _tempController.text = cl.temperatura ?? '';
      _problemController.text = cl.problema ?? '';
      _solutionController.text = cl.solucao ?? '';
      _materialController.text = cl.material ?? '';
      _obsController.text = cl.observacoes ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tempController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _materialController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  bool get _isInicial => widget.mode == ChecklistWizardMode.inicial;

  int get _totalPages {
    if (_isInicial) {
      // 1: Condição, 2: Foto Antes, 3: Problema (se houver)
      return _statusEquipamento == 'PROBLEMA_IDENTIFICADO' ? 3 : 2;
    } else {
      // 1: Foto Depois, 2: Temperatura Aferida e Observações
      return 2;
    }
  }

  Future<void> _pickPhoto(String tipo) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tirar foto com a Câmera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final res = await _ds.uploadChecklistPhoto(
        widget.etapaId,
        widget.equipmentId,
        tipo: tipo,
        imagePath: picked.path,
      );

      final url = res['url']?.toString() ??
          res['path']?.toString() ??
          (res['data'] is Map
              ? (res['data']['url']?.toString() ?? res['data']['path']?.toString())
              : null);

      if (!mounted) return;
      setState(() {
        final finalRef = (url != null && url.isNotEmpty) ? url : picked.path;
        if (tipo == 'antes') {
          _fotoAntesUrl = finalRef;
        } else {
          _fotoDepoisUrl = finalRef;
        }
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto "$tipo" salva com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context, false);
    }
  }

  Future<void> _save() async {
    // Validações antes de salvar
    if (_isInicial) {
      if (_fotoAntesUrl == null || _fotoAntesUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A foto do equipamento (Antes) é obrigatória para iniciar.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _pageController.animateToPage(1,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        return;
      }
      if (_statusEquipamento == 'PROBLEMA_IDENTIFICADO' &&
          _problemController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descreva o defeito identificado no aparelho.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } else {
      if (_fotoDepoisUrl == null || _fotoDepoisUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A foto do serviço finalizado (Depois) é obrigatória.'),
            backgroundColor: AppColors.warning,
          ),
        );
        _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final payload = <String, dynamic>{
        'status_equipamento': _statusEquipamento,
        'temperatura': _tempController.text.trim(),
        'observacoes': _obsController.text.trim(),
      };

      String sanitizePhotoPath(String p) {
        var s = p.replaceAll(RegExp(r'/+'), '/');
        s = s.replaceFirst('/filestorages_lobotec/', '');
        s = s.replaceFirst('filestorages_lobotec/', '');
        s = s.replaceFirst('/storage/', '');
        s = s.replaceFirst('storage/', '');
        return s;
      }

      if (_fotoAntesUrl != null) payload['foto_antes'] = sanitizePhotoPath(_fotoAntesUrl!);
      if (_fotoDepoisUrl != null) payload['foto_depois'] = sanitizePhotoPath(_fotoDepoisUrl!);

      if (_statusEquipamento == 'PROBLEMA_IDENTIFICADO') {
        payload['problema'] = _problemController.text.trim();
        payload['solucao'] = _solutionController.text.trim();
        payload['material'] = _materialController.text.trim();
      }

      await _ds.saveChecklist(widget.etapaId, widget.equipmentId, payload);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isInicial
              ? 'Vistoria inicial concluída! Tarefas liberadas.'
              : 'Foto final registrada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar checklist: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) {
          _prevPage();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            _isInicial ? 'Vistoria Inicial' : 'Checklist de Saída',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _prevPage,
          ),
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: _isInicial ? _buildInicialPages() : _buildFinalPages(),
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_currentPage + 1} de $_totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(((_currentPage + 1) / _totalPages) * 100).toInt()}% concluído',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInicialPages() {
    final pages = <Widget>[
      _buildCardCondicao(),
      _buildCardFoto(
        tipo: 'antes',
        fotoUrl: _fotoAntesUrl,
        titulo: 'Tire a Foto do Aparelho (Antes)',
        subtitulo: 'Registre como o equipamento foi encontrado antes do serviço.',
      ),
    ];

    if (_statusEquipamento == 'PROBLEMA_IDENTIFICADO') {
      pages.add(_buildCardDefeito());
    }

    return pages;
  }

  List<Widget> _buildFinalPages() {
    return [
      _buildCardFoto(
        tipo: 'depois',
        fotoUrl: _fotoDepoisUrl,
        titulo: 'Foto do Serviço Concluído (Depois)',
        subtitulo: 'Tire uma foto nítida do equipamento pronto e finalizado.',
      ),
      _buildCardTemperaturaEObservacoes(),
    ];
  }

  Widget _buildCardCondicao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qual o estado do aparelho?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecione se o equipamento está funcionando ou com falhas antes de mexer nele.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            title: 'Funcionando Normal',
            description: 'Equipamento liga e opera normalmente, sem falhas aparentes.',
            icon: Icons.check_circle_outline,
            isSelected: _statusEquipamento == 'OK',
            activeColor: AppColors.success,
            onTap: () => setState(() => _statusEquipamento = 'OK'),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            title: 'Com Problema / Defeito',
            description: 'Aparelho não liga, apresenta código de erro, ruído ou vazamento.',
            icon: Icons.warning_amber_rounded,
            isSelected: _statusEquipamento == 'PROBLEMA_IDENTIFICADO',
            activeColor: AppColors.warning,
            onTap: () => setState(() => _statusEquipamento = 'PROBLEMA_IDENTIFICADO'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isSelected ? activeColor : Colors.grey.shade400)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFoto({
    required String tipo,
    required String? fotoUrl,
    required String titulo,
    required String subtitulo,
  }) {
    final hasPhoto = fotoUrl != null && fotoUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (hasPhoto) ...[
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.success, width: 2),
                color: Colors.black12,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImagePreview(fotoUrl),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Foto Registrada',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isUploadingPhoto ? null : () => _pickPhoto(tipo),
                icon: const Icon(Icons.refresh),
                label: const Text('Tirar Outra Foto'),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: _isUploadingPhoto ? null : () => _pickPhoto(tipo),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _isUploadingPhoto
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Enviando foto...'),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Toque para abrir a câmera',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ou escolha da galeria',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        ApiConstants.resolveStorageUrl(path),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stack) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Image.network(
      ApiConstants.resolveStorageUrl(path),
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }


  Widget _buildCardDefeito() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes do Defeito',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Descreva o problema encontrado para registrar no histórico.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _problemController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Problema Identificado *',
              hintText: 'Ex: Compressor não arma, capacitor estufado...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _solutionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Solução Sugerida (Opcional)',
              hintText: 'Ex: Troca de capacitor 35uF...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _materialController,
            decoration: InputDecoration(
              labelText: 'Material / Peça Necessária (Opcional)',
              hintText: 'Ex: Capacitor 35uF 440V',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTemperaturaEObservacoes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Testes Finais e Observações',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Informe a temperatura final e notas adicionais da conclusão do serviço.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _tempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Temperatura Final (°C)',
              hintText: 'Ex: 17.5',
              suffixText: '°C',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _obsController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Observações Finais do Serviço',
              hintText: 'Ex: Limpeza completa efetuada, dreno desobstruído...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final isLast = _currentPage == _totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: _isLoading ? null : _prevPage,
              child: const Text('Voltar'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: CustomButton(
              text: isLast
                  ? (_isInicial ? 'CONCLUIR VISTORIA' : 'SALVAR E FINALIZAR')
                  : 'PRÓXIMO',
              isLoading: _isLoading,
              onPressed: _isLoading || _isUploadingPhoto ? () {} : _nextPage,
            ),
          ),
        ],
      ),
    );
  }
}
