import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/constants/api_constants.dart';
import '../core/di/injection_container.dart';
import '../core/utils/date_formatter.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/checklist_model.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../features/execution/data/models/task_model.dart';
import '../widgets/status_badge.dart';
import 'task_form_screen.dart';

/// Visualização somente leitura do equipamento (histórico / etapa finalizada).
class EquipmentHistoryDetailScreen extends StatefulWidget {
  final int etapaId;
  final int equipmentId;

  const EquipmentHistoryDetailScreen({
    super.key,
    required this.etapaId,
    required this.equipmentId,
  });

  @override
  State<EquipmentHistoryDetailScreen> createState() =>
      _EquipmentHistoryDetailScreenState();
}

class _EquipmentHistoryDetailScreenState
    extends State<EquipmentHistoryDetailScreen> {
  late final ExecutionRemoteDataSource _dataSource;
  EquipmentModel? _equipment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataSource = getIt<ExecutionRemoteDataSource>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final eq = await _dataSource.getEquipmentDetail(
        widget.etapaId,
        widget.equipmentId,
      );
      if (!mounted) return;
      setState(() {
        _equipment = eq;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
            padding: const EdgeInsets.all(24),
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
                  onPressed: _load,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eq = _equipment!;
    final checklist = eq.checklist;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          eq.tag?.isNotEmpty == true ? 'TAG: ${eq.tag}' : 'Equipamento',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeaderCard(eq),
            const SizedBox(height: 14),
            _buildCadastroCard(eq),
            const SizedBox(height: 14),
            _buildVistoriaAntesCard(checklist),
            const SizedBox(height: 14),
            _buildVistoriaDepoisCard(checklist),
            const SizedBox(height: 14),
            _buildTarefasCard(eq),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(EquipmentModel eq) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eq.tipoEquipamento ?? 'Equipamento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadge(
                label: eq.isFinalizado ? 'FINALIZADO' : eq.status,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eq.tag?.isNotEmpty == true
                ? 'TAG: ${eq.tag}'
                : 'TAG não informada',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCadastroCard(EquipmentModel eq) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Marca', eq.marca?.isNotEmpty == true ? eq.marca! : '—'),
      MapEntry('Modelo', eq.modelo?.isNotEmpty == true ? eq.modelo! : '—'),
      MapEntry(
        'Capacidade',
        eq.btu != null && eq.btu!.isNotEmpty ? '${eq.btu} BTU' : '—',
      ),
      MapEntry(
        'Evaporadora',
        eq.evaporadora?.isNotEmpty == true ? eq.evaporadora! : '—',
      ),
      MapEntry(
        'Condensadora',
        eq.condensadora?.isNotEmpty == true ? eq.condensadora! : '—',
      ),
      MapEntry(
        'Localização',
        eq.localizacao?.isNotEmpty == true ? eq.localizacao! : '—',
      ),
      if (eq.observacoes != null && eq.observacoes!.isNotEmpty)
        MapEntry('Observações', eq.observacoes!),
    ];

    return _sectionCard(
      title: 'Cadastro do aparelho',
      icon: Icons.precision_manufacturing_outlined,
      child: Column(
        children: rows.map((e) => _infoRow(e.key, e.value)).toList(),
      ),
    );
  }

  Widget _buildVistoriaAntesCard(ChecklistModel? checklist) {
    final fotos = checklist?.fotosAntes ?? const <ChecklistPhoto>[];
    final hasProblema = checklist?.hasProblema == true;
    final condicao = checklist == null
        ? null
        : (hasProblema
            ? 'Necessita de Corretiva'
            : (checklist.statusEquipamento == 'OK'
                ? 'Normal'
                : checklist.statusEquipamento));

    return _sectionCard(
      title: 'Vistoria inicial (Antes)',
      icon: Icons.photo_camera_back_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checklist == null || !checklist.isPreenchido)
            const Text(
              'Checklist não preenchido neste atendimento.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else ...[
            if (condicao != null) _infoRow('Condição', condicao),
            if (hasProblema) ...[
              _infoRow('Problema', checklist.problema ?? '—'),
              if (checklist.solucao != null && checklist.solucao!.isNotEmpty)
                _infoRow('Solução', checklist.solucao!),
              if (checklist.material != null && checklist.material!.isNotEmpty)
                _infoRow('Material', checklist.material!),
              if (checklist.tempoResolucao != null &&
                  checklist.tempoResolucao!.isNotEmpty)
                _infoRow('Tempo de resolução', checklist.tempoResolucao!),
            ],
          ],
          const SizedBox(height: 10),
          _photoStrip(
            fotos: fotos,
            emptyLabel: 'Nenhuma foto do antes registrada.',
          ),
        ],
      ),
    );
  }

  Widget _buildVistoriaDepoisCard(ChecklistModel? checklist) {
    final fotos = checklist?.fotosDepois ?? const <ChecklistPhoto>[];

    return _sectionCard(
      title: 'Vistoria final (Depois)',
      icon: Icons.photo_camera_front_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checklist != null && checklist.isPreenchido) ...[
            if (checklist.temperatura != null &&
                checklist.temperatura!.isNotEmpty)
              _infoRow('Temperatura', '${checklist.temperatura}°C'),
            if (checklist.observacoes != null &&
                checklist.observacoes!.isNotEmpty)
              _infoRow('Observações', checklist.observacoes!),
            if ((checklist.temperatura == null ||
                    checklist.temperatura!.isEmpty) &&
                (checklist.observacoes == null ||
                    checklist.observacoes!.isEmpty) &&
                fotos.isEmpty)
              const Text(
                'Sem dados adicionais da vistoria final.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ] else
            const Text(
              'Checklist não preenchido neste atendimento.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 10),
          _photoStrip(
            fotos: fotos,
            emptyLabel: 'Nenhuma foto do depois registrada.',
          ),
        ],
      ),
    );
  }

  Widget _buildTarefasCard(EquipmentModel eq) {
    final tasks = eq.tarefas;
    final feitas = tasks.where((t) => t.isFeito).length;

    return _sectionCard(
      title: 'Tarefas ($feitas/${tasks.length})',
      icon: Icons.checklist_rtl,
      child: tasks.isEmpty
          ? const Text(
              'Nenhuma tarefa vinculada a este aparelho.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (var i = 0; i < tasks.length; i++) ...[
                  if (i > 0) const Divider(height: 18),
                  _buildTaskRow(tasks[i]),
                ],
              ],
            ),
    );
  }

  Widget _buildTaskRow(TaskModel t) {
    final canViewForm =
        t.temFormulario && t.formularioStatus == 'ENVIADO';
    final feitoLabel = DateFormatter.formatFullDateTime(t.feitoAt);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: canViewForm
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskFormScreen(
                    tarefaId: t.id,
                    tarefaNome: t.nome,
                    readOnly: true,
                  ),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              t.isFeito ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: t.isFeito ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.nome,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.isFeito
                        ? (feitoLabel.isNotEmpty
                            ? 'Concluída em $feitoLabel'
                            : 'Concluída')
                        : 'Pendente',
                    style: TextStyle(
                      fontSize: 12,
                      color: t.isFeito
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (t.temFormulario) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.formularioStatus == 'ENVIADO'
                          ? 'Formulário enviado — toque para ver'
                          : 'Formulário não enviado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.formularioStatus == 'ENVIADO'
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canViewForm)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _photoStrip({
    required List<ChecklistPhoto> fotos,
    required String emptyLabel,
  }) {
    if (fotos.isEmpty) {
      return Text(
        emptyLabel,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final url = ApiConstants.resolveStorageUrl(fotos[i].url);
          return GestureDetector(
            onTap: () => _showImageDialog(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 104,
                height: 104,
                color: Colors.grey.shade200,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
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
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
                  errorBuilder: (_, __, ___) => Container(
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
}
