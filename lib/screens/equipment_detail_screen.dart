import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../features/execution/data/models/task_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'equipment_checklist_screen.dart';
import 'equipment_register_screen.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipamento iniciado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadEquipment();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao iniciar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleToggleTask(TaskModel task) async {
    try {
      final newStatus = task.isFeito ? 'PENDENTE' : 'FEITO';
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
    try {
      final res = await _dataSource.finalizeEquipment(
        widget.etapaId,
        widget.equipmentId,
        confirmPendencias: confirmPendencias,
      );

      if (res['code'] == 'CONFIRMATION_REQUIRED') {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Pendências no Equipamento'),
            content: Text(
              '${res['message']}\n\nDeseja confirmar a finalização mesmo com pendências?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
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
                        builder: (_) => EquipmentRegisterScreen(equipment: eq),
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
                  'CHECKLIST TÉCNICO',
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
            if (checklist != null && isPreenchido) ...[
              _buildInfoRow('Condição:', checklist.statusEquipamento ?? 'OK'),
              if (checklist.hasProblema) ...[
                _buildInfoRow('Problema:', checklist.problema ?? '-'),
                _buildInfoRow('Solução:', checklist.solucao ?? '-'),
              ],
              if (checklist.temperatura != null)
                _buildInfoRow('Temperatura:', '${checklist.temperatura}°C'),
            ] else ...[
              const Text(
                'O checklist inicial e testes ainda não foram enviados.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                child: Text(isPreenchido ? 'Editar Checklist' : 'Preencher Checklist'),
              ),
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
              ...tasks.map((t) => CheckboxListTile(
                    title: Text(
                      t.nome,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: t.isFeito ? TextDecoration.lineThrough : null,
                        color: t.isFeito ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    value: t.isFeito,
                    activeColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                    onChanged: eq.isFinalizado ? null : (_) => _handleToggleTask(t),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
