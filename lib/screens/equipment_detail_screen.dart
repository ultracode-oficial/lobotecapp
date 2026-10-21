import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants/api_constants.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../features/execution/data/models/task_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'equipment_checklist_screen.dart';
import 'equipment_checklist_wizard_screen.dart';
import 'equipment_register_screen.dart';
import 'task_form_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final int etapaId;
  final int equipmentId;

  const EquipmentDetailScreen({
    super.key,
    required this.etapaId,
    required this.equipmentId,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  late final ExecutionRemoteDataSource _dataSource;
  EquipmentModel? _equipment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataSource = getIt<ExecutionRemoteDataSource>();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eq = await _dataSource.getEquipmentDetail(
        widget.etapaId,
        widget.equipmentId,
      );
      if (mounted) {
        setState(() {
          _equipment = eq;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStartEquipment() async {
    try {
      await _dataSource.startEquipment(widget.etapaId, widget.equipmentId);
    } catch (e) {
      debugPrint('Aviso ao iniciar equipamento: $e');
    }

    // Abre imediatamente o checklist interativo de vistoria inicial (Perguntas e Respostas)
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentChecklistWizardScreen(
          etapaId: widget.etapaId,
          equipmentId: widget.equipmentId,
          checklist: _equipment?.checklist,
          mode: ChecklistWizardMode.inicial,
        ),
      ),
    );
    _loadEquipment();
  }

  /// Antes de finalizar o equipamento, checa se as tarefas possuem formulário ativo.
  /// Se a API retornar 404 (sem formulário vinculado), ignora e segue normalmente.
  /// Se a API retornar 200 com perguntas, abre para o técnico preencher.
  Future<bool> _checkAndFillPendingForms() async {
    final tarefas = _equipment?.tarefas ?? [];
    for (final t in tarefas) {
      if (t.formularioStatus == 'ENVIADO') continue;

      try {
        final formData = await _dataSource.getTaskForm(t.id);
        final rawQuestions = formData['perguntas'];
        final hasQuestions = rawQuestions is List && rawQuestions.isNotEmpty;

        if (hasQuestions) {
          if (!mounted) return false;
          final formDone = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => TaskFormScreen(tarefaId: t.id, tarefaNome: t.nome),
            ),
          );
          if (formDone != true) {
            // Técnico cancelou o formulário, interrompe finalização
            return false;
          }
          await _loadEquipment();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // 404: Sem formulário vinculado/publicado. Segue em frente normalmente!
          debugPrint('Tarefa ${t.id} sem formulário (404), seguindo normalmente.');
        } else {
          debugPrint('Aviso ao consultar formulário da tarefa ${t.id}: $e');
        }
      } catch (e) {
        debugPrint('Aviso ao consultar formulário da tarefa ${t.id}: $e');
      }
    }
    return true;
  }

  Future<void> _handleToggleTask(TaskModel task) async {
    // Validação obrigatória: É necessário preencher a vistoria inicial antes de executar tarefas
    final hasFotoAntes = _equipment?.checklist?.fotoAntesUrl != null &&
        _equipment!.checklist!.fotoAntesUrl!.isNotEmpty;
    final isChecklistPreenchido = _equipment?.checklist?.isPreenchido == true;

    if (!hasFotoAntes || !isChecklistPreenchido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Realize a vistoria inicial (Foto do Antes) antes de executar tarefas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentChecklistWizardScreen(
            etapaId: widget.etapaId,
            equipmentId: widget.equipmentId,
            checklist: _equipment?.checklist,
            mode: ChecklistWizardMode.inicial,
          ),
        ),
      );
      _loadEquipment();
      return;
    }

    final newStatus = task.isFeito ? 'PENDENTE' : 'FEITO';

    // Se estiver marcando a tarefa como FEITO, checa se esta é a última tarefa pendente do aparelho!
    if (newStatus == 'FEITO') {
      final tarefas = _equipment?.tarefas ?? [];
      final outrasPendentes = tarefas.where((t) => !t.isFeito && t.id != task.id).length;
      final isUltimaTarefa = outrasPendentes == 0;

      if (isUltimaTarefa) {
        // Ao concluir a última tarefa, o equipamento será finalizado.
        // Garante que o checklist final (Foto do Depois / Temperatura) seja feito antes!
        final checklist = _equipment?.checklist;
        final hasFotoDepois = checklist?.fotoDepoisUrl != null && checklist!.fotoDepoisUrl!.isNotEmpty;

        if (!hasFotoDepois) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Última tarefa! Registre a foto de conclusão (Depois) para finalizar.'),
              backgroundColor: AppColors.primary,
            ),
          );
          final completed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentChecklistWizardScreen(
                etapaId: widget.etapaId,
                equipmentId: widget.equipmentId,
                checklist: checklist,
                mode: ChecklistWizardMode.finalizacao,
              ),
            ),
          );
          if (completed != true) return;
          await _loadEquipment();
        }
      }
    }

    try {
      await _dataSource.toggleTask(task.id, status: newStatus);
      _loadEquipment();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar tarefa: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleFinalizeEquipment({bool confirmPendencias = false}) async {
    final checklist = _equipment?.checklist;
    final isChecklistPreenchido = checklist?.isPreenchido == true;
    final hasFotoDepois = checklist?.fotoDepoisUrl != null && checklist!.fotoDepoisUrl!.isNotEmpty;

    // Se ainda não tirou a foto do depois, abre a tela de finalização antes de enviar
    if (!hasFotoDepois) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tire a foto do serviço concluído (Foto do Depois) para finalizar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentChecklistWizardScreen(
            etapaId: widget.etapaId,
            equipmentId: widget.equipmentId,
            checklist: checklist,
            mode: ChecklistWizardMode.finalizacao,
          ),
        ),
      );
      if (completed != true) return;
      await _loadEquipment();
    }

    if (!mounted) return;

    // É obrigatório preencher o Checklist Técnico antes de finalizar o equipamento
    if (!isChecklistPreenchido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'É necessário preencher o Checklist Técnico antes de finalizar o equipamento.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Checa se alguma tarefa possui formulário ativo antes de finalizar.
    // Se der 404, ignora e segue normalmente. Se tiver formulário com perguntas, abre para preencher.
    final formsOk = await _checkAndFillPendingForms();
    if (!formsOk) return;
    if (!mounted) return;

    try {
      final res = await _dataSource.finalizeEquipment(
        widget.etapaId,
        widget.equipmentId,
        confirmPendencias: confirmPendencias,
      );

      if (res['code'] == 'CONFIRMATION_REQUIRED') {
        if (!mounted) return;
        final pendenciasData = res['data'] is Map ? res['data'] as Map : {};
        final tarefasPendentes = pendenciasData['tarefas_pendentes'] ?? 0;
        final checklistPendente = pendenciasData['checklist_pendente'] == true;
        final formsPendentes = pendenciasData['formularios_pendentes'] ?? 0;

        // Se NÃO há tarefas pendentes nem checklist pendente (o backend só está acusando
        // formulário pendente de um tipo que nem tem formulário publicado),
        // confirma e finaliza automaticamente sem travar o técnico com popup!
        if (tarefasPendentes == 0 && !checklistPendente && formsPendentes > 0) {
          _handleFinalizeEquipment(confirmPendencias: true);
          return;
        }

        final pendenciasList = <String>[];
        if (checklistPendente) pendenciasList.add('• Checklist técnico pendente');
        if (tarefasPendentes > 0) pendenciasList.add('• $tarefasPendentes tarefa(s) pendente(s)');
        if (formsPendentes > 0) pendenciasList.add('• $formsPendentes formulário(s) pendente(s)');

        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pendências no Equipamento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res['message']?.toString() ??
                      'Existem pendências neste equipamento. Confirme para finalizar mesmo assim.',
                  style: const TextStyle(fontSize: 14),
                ),
                if (pendenciasList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...pendenciasList.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          p,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                      )),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Deseja confirmar a finalização mesmo com pendências?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _handleFinalizeEquipment(confirmPendencias: true);
                },
                child: const Text('Confirmar e Finalizar'),
              ),
            ],
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipamento finalizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar equipamento: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Equipamento')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes do Equipamento')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Equipamento não encontrado.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadEquipment,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eq = _equipment!;
    final isFinalizado = eq.isFinalizado;
    final isEmAndamento = eq.isEmAndamento;

    return Scaffold(
      appBar: AppBar(
        title: Text(eq.tag?.isNotEmpty == true ? 'TAG: ${eq.tag}' : 'Equipamento #${eq.id}'),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEquipment,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(eq),
            const SizedBox(height: 20),

            if (!isEmAndamento && !isFinalizado) ...[
              CustomButton(
                text: 'INICIAR EQUIPAMENTO',
                onPressed: _handleStartEquipment,
              ),
              const SizedBox(height: 20),
            ],

            _buildChecklistCard(eq),
            const SizedBox(height: 20),

            _buildTasksCard(eq),
            const SizedBox(height: 32),

            if (!isFinalizado)
              CustomButton(
                text: 'FINALIZAR EQUIPAMENTO',
                onPressed: () => _handleFinalizeEquipment(),
                isPrimary: isEmAndamento,
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(EquipmentModel eq) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  eq.tipoEquipamento ?? 'Ar Condicionado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusBadge(
                  label: eq.status,
                  color: eq.isFinalizado
                      ? AppColors.success
                      : (eq.isEmAndamento ? AppColors.primary : AppColors.warning),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('TAG:', eq.tag ?? 'Não informada (Genérico)'),
            _buildInfoRow('Marca/Modelo:', '${eq.marca ?? '-'} ${eq.modelo ?? ''}'),
            _buildInfoRow('Capacidade:', eq.btu != null ? '${eq.btu} BTU' : '-'),
            _buildInfoRow('Localização:', eq.localizacao ?? '-'),
            if (eq.isGeneric) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Registrar / Identificar TAG'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipmentRegisterScreen(
                          equipment: eq,
                          etapaId: widget.etapaId,
                        ),
                      ),
                    ).then((_) => _loadEquipment());
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(EquipmentModel eq) {
    final checklist = eq.checklist;
    final isPreenchido = checklist?.isPreenchido == true;
    final fotoAntes = checklist?.fotoAntesUrl;
    final fotoDepois = checklist?.fotoDepoisUrl;
    final hasFotoAntes = fotoAntes != null && fotoAntes.isNotEmpty;
    final hasFotoDepois = fotoDepois != null && fotoDepois.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CHECKLIST & VISTORIAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                StatusBadge(
                  label: isPreenchido ? 'PREENCHIDO' : 'PENDENTE',
                  color: isPreenchido ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Foto do Antes:',
              hasFotoAntes ? 'Registrada' : 'Pendente (Obrigatória no Início)',
            ),
            _buildInfoRow(
              'Foto do Depois:',
              hasFotoDepois ? 'Registrada' : 'Pendente (Obrigatória no Final)',
            ),
            if (hasFotoAntes || hasFotoDepois) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (hasFotoAntes) ...[
                    _buildPhotoThumbnail('Foto Antes', fotoAntes),
                    const SizedBox(width: 12),
                  ],
                  if (hasFotoDepois) ...[
                    _buildPhotoThumbnail('Foto Depois', fotoDepois),
                  ],
                ],
              ),
            ],
            if (checklist != null && isPreenchido) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Condição:', checklist.statusEquipamento ?? 'OK'),
              if (checklist.hasProblema) ...[
                _buildInfoRow('Problema:', checklist.problema ?? '-'),
                _buildInfoRow('Solução:', checklist.solucao ?? '-'),
              ],
              if (checklist.temperatura != null)
                _buildInfoRow('Temperatura Final:', '${checklist.temperatura}°C'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(hasFotoAntes ? Icons.check_circle : Icons.camera_alt, size: 16),
                    label: Text(hasFotoAntes ? 'Vistoria Inicial OK' : 'Fazer Vistoria'),
                    onPressed: eq.isFinalizado
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EquipmentChecklistWizardScreen(
                                  etapaId: widget.etapaId,
                                  equipmentId: widget.equipmentId,
                                  checklist: checklist,
                                  mode: ChecklistWizardMode.inicial,
                                ),
                              ),
                            ).then((_) => _loadEquipment());
                          },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Visualizar / Editar Completo',
                  icon: const Icon(Icons.edit_note, color: AppColors.primary),
                  onPressed: eq.isFinalizado
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EquipmentChecklistScreen(
                                etapaId: widget.etapaId,
                                equipmentId: widget.equipmentId,
                                checklist: checklist,
                              ),
                            ),
                          ).then((_) => _loadEquipment());
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String label, String photoPath) {
    final resolvedUrl = ApiConstants.resolveStorageUrl(photoPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showImageDialog(resolvedUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: Colors.grey.shade200,
              child: Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.black87,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stack) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Text('Não foi possível carregar a imagem.'),
                  ),
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

  Widget _buildTasksCard(EquipmentModel eq) {
    final tasks = eq.tarefas;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TAREFAS DO APARELHO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${tasks.where((t) => t.isFeito).length}/${tasks.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty) ...[
              const Text(
                'Nenhuma tarefa específica vinculada.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ] else ...[
              ...tasks.map((t) => _buildTaskItem(eq, t)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(EquipmentModel eq, TaskModel t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: eq.isFinalizado ? null : () => _handleToggleTask(t),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: t.isFeito,
                activeColor: AppColors.success,
                onChanged: eq.isFinalizado ? null : (_) => _handleToggleTask(t),
              ),
              Expanded(
                child: Text(
                  t.nome,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: t.isFeito ? TextDecoration.lineThrough : null,
                    color: t.isFeito ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
