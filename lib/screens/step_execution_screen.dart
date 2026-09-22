import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../core/utils/date_formatter.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_bloc.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_event.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'checkin_map_screen.dart';
import 'equipment_detail_screen.dart';
import 'signature_capture_screen.dart';

class StepExecutionScreen extends StatelessWidget {
  final int etapaId;

  const StepExecutionScreen({super.key, required this.etapaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StepExecutionBloc>(
      create: (_) =>
          getIt<StepExecutionBloc>()..add(FetchStepDetailEvent(etapaId)),
      child: _StepExecutionView(etapaId: etapaId),
    );
  }
}

class _StepExecutionView extends StatefulWidget {
  final int etapaId;

  const _StepExecutionView({required this.etapaId});

  @override
  State<_StepExecutionView> createState() => _StepExecutionViewState();
}

class _StepExecutionViewState extends State<_StepExecutionView> {
  StepModel? _currentStep;

  Future<void> _collectSignature(BuildContext context, StepModel step) async {
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SignatureCaptureScreen(
          clienteNome: step.cliente?.nome,
          numeroOs: step.numeroOs,
        ),
      ),
    );

    if (imagePath != null && context.mounted) {
      context.read<StepExecutionBloc>().add(
            UploadSignatureEvent(widget.etapaId, imagePath),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StepExecutionBloc, StepExecutionState>(
      listener: (context, state) {
        if (state is StepExecutionLoaded) {
          setState(() => _currentStep = state.step);
        } else if (state is StepCheckInSuccess) {
          setState(() => _currentStep = state.step);
        } else if (state is StepSignatureUploaded) {
          setState(() => _currentStep = state.step);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assinatura salva com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is StepFinalizedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is StepConfirmationRequired) {
          showDialog(
            context: context,
            builder: (dialogCtx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Confirmar Finalização'),
              content: Text(
                '${state.message}\n\nExistem equipamentos não iniciados. Deseja desvinculá-los e finalizar a etapa mesmo assim?',
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
                    context.read<StepExecutionBloc>().add(
                          FinalizeStepEvent(
                            widget.etapaId,
                            confirmRemocaoNaoIniciados: true,
                          ),
                        );
                  },
                  child: const Text('Confirmar e Finalizar'),
                ),
              ],
            ),
          );
        } else if (state is StepExecutionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StepExecutionLoading && _currentStep == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Atendimento')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando dados do atendimento...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final step = _currentStep;
        if (step != null) {
          final isCheckedIn = step.isCheckedIn;
          final isFinalized = step.isFinalized;
          final hasSignature = step.temAssinatura || (step.assinaturaUrl?.isNotEmpty == true);

          final totalEquipments = (step.equipamentosTotal != null && step.equipamentosTotal! > 0)
              ? step.equipamentosTotal!
              : step.equipamentos.length;
          final completedEquipments = step.equipamentosDone != null
              ? step.equipamentosDone!
              : step.equipamentos.where((e) => e.isFinalizado).length;
          final double progress = totalEquipments > 0
              ? (completedEquipments / totalEquipments).clamp(0.0, 1.0)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                step.titulo ?? 'Etapa #${step.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const BackButton(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context
                        .read<StepExecutionBloc>()
                        .add(FetchStepDetailEvent(widget.etapaId));
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<StepExecutionBloc>()
                    .add(FetchStepDetailEvent(widget.etapaId));
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. BANNER HERO COM DADOS DA OS E DO CLIENTE
                  _buildHeroHeaderCard(context, step),
                  const SizedBox(height: 16),

                  // 2. AVISO SE CHECK-IN NÃO FOI FEITO NA TELA ANTERIOR
                  if (!isCheckedIn && !isFinalized) ...[
                    _buildPendingCheckInBanner(context, step),
                    const SizedBox(height: 16),
                  ],

                  // 3. BARRA DE PROGRESSO E CABEÇALHO DE EQUIPAMENTOS
                  _buildEquipmentsSectionHeader(
                    completedEquipments,
                    totalEquipments,
                    progress,
                  ),
                  const SizedBox(height: 12),

                  // 4. LISTA DE EQUIPAMENTOS (Foco total na execução)
                  if (step.equipamentos.isEmpty)
                    _buildEmptyEquipmentsCard(context, totalEquipments)
                  else
                    ...step.equipamentos.map(
                      (eq) => _buildEquipmentCard(
                        context,
                        eq,
                        isCheckedIn && !isFinalized,
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: (isCheckedIn && !isFinalized)
                ? _buildBottomBar(context, step, hasSignature)
                : null,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Atendimento')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                const Text('Não foi possível carregar o atendimento.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  onPressed: () {
                    context
                        .read<StepExecutionBloc>()
                        .add(FetchStepDetailEvent(widget.etapaId));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeaderCard(BuildContext context, StepModel step) {
    String statusLabel = 'AGUARDANDO CHECK-IN';
    Color statusBg = AppColors.warning.withValues(alpha: 0.25);
    Color statusTextColor = AppColors.warning;

    if (step.isFinalized) {
      statusLabel = 'FINALIZADO';
      statusBg = AppColors.success.withValues(alpha: 0.3);
      statusTextColor = Colors.white;
    } else if (step.isCheckedIn) {
      statusLabel = 'EM ANDAMENTO';
      statusBg = Colors.white.withValues(alpha: 0.2);
      statusTextColor = Colors.white;
    }

    final dataInicioFmt = DateFormatter.formatDateTime(step.dataInicio);
    final clienteNome = step.cliente?.nome ?? 'Cliente não identificado';
    final endereco = step.cliente?.endereco ?? 'Endereço não informado';
    final numeroOs = step.numeroOs ?? (step.servicoId != null ? 'OS #${step.servicoId}' : 'OS');
    final tipoServico = step.tipoServicoNome ?? 'Climatização';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Número OS e Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  numeroOs,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nome do Cliente
          Text(
            clienteNome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),

          // Chip do Tipo de Serviço
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tipoServico,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Endereço do Cliente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  endereco,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          // Horário Previsto
          if (dataInicioFmt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Agendado: $dataInicioFmt',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],

          // Colegas / Equipe alocada
          if (step.colegas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.engineering, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Técnico(s): ${step.colegas.join(", ")}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCheckInBanner(BuildContext context, StepModel step) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'O Check-in de presença deve ser realizado na página da Ordem de Serviço para liberar a execução.',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Ver Mapa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<StepExecutionBloc>(),
                    child: CheckInMapScreen(step: step),
                  ),
                ),
              ).then((res) {
                if (res == true && context.mounted) {
                  context.read<StepExecutionBloc>().add(FetchStepDetailEvent(widget.etapaId));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentsSectionHeader(
    int completed,
    int total,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EQUIPAMENTOS DA ETAPA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$completed de $total concluído(s)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyEquipmentsCard(BuildContext context, int totalExpected) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.hvac_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                totalExpected > 0
                    ? '$totalExpected equipamento(s) vinculado(s)'
                    : 'Nenhum equipamento cadastrado',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                totalExpected > 0
                    ? 'Toque abaixo para sincronizar a lista de aparelhos da etapa.'
                    : 'Esta etapa não possui aparelhos atribuídos no momento.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Sincronizar Equipamentos'),
                onPressed: () {
                  context
                      .read<StepExecutionBloc>()
                      .add(FetchStepDetailEvent(widget.etapaId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    EquipmentModel eq,
    bool isActive,
  ) {
    String status = 'Aguardando Início';
    Color statusColor = AppColors.warning;
    String subtext = 'Toque para iniciar execução';
    Color subtextColor = AppColors.textSecondary;

    if (eq.isGeneric || eq.registroPendente) {
      status = 'Registro pendente';
      statusColor = AppColors.warning;
      subtext = 'Necessita cadastrar TAG/ficha técnica';
      subtextColor = AppColors.error;
    } else if (eq.isFinalizado) {
      status = 'Finalizado';
      statusColor = AppColors.success;
      subtext = 'Equipamento concluído com sucesso';
      subtextColor = AppColors.success;
    } else if (eq.isEmAndamento) {
      status = 'Em Andamento';
      statusColor = AppColors.primary;
      final completed = eq.tarefas.where((t) => t.isFeito).length;
      subtext = '$completed/${eq.tarefas.length} tarefas realizadas';
      subtextColor = AppColors.primary;
    }

    final brandModel = [
      if (eq.marca?.isNotEmpty == true) eq.marca,
      if (eq.modelo?.isNotEmpty == true) eq.modelo,
      if (eq.btu?.isNotEmpty == true) '${eq.btu} BTU',
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? (eq.isFinalizado ? AppColors.success : AppColors.primary.withValues(alpha: 0.3))
              : AppColors.border,
          width: eq.isFinalizado ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isActive
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentDetailScreen(
                      etapaId: widget.etapaId,
                      equipmentId: eq.id,
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    context
                        .read<StepExecutionBloc>()
                        .add(FetchStepDetailEvent(widget.etapaId));
                  }
                });
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Confirme a presença via CHECK-IN para poder executar os equipamentos.',
                    ),
                  ),
                );
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.ac_unit_rounded,
                      color: isActive ? AppColors.primary : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                eq.tag?.isNotEmpty == true
                                    ? 'TAG: ${eq.tag}'
                                    : (eq.tipoEquipamento ?? 'Aparelho #${eq.id}'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(label: status, color: statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          brandModel.isNotEmpty ? brandModel : 'Aparelho de Ar-Condicionado',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.play_circle_outline : Icons.lock_outline,
                        size: 16,
                        color: subtextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtext,
                        style: TextStyle(
                          color: subtextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, StepModel step, bool hasSignature) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: hasSignature ? 'ASSINATURA COLETADA' : 'COLETAR ASSINATURA DO CLIENTE',
              isPrimary: !hasSignature,
              onPressed: () => _collectSignature(context, step),
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'FINALIZAR ATENDIMENTO',
              isPrimary: hasSignature,
              onPressed: () {
                if (!hasSignature) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'É obrigatório coletar a assinatura do cliente antes de finalizar.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                context.read<StepExecutionBloc>().add(
                      FinalizeStepEvent(widget.etapaId),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
