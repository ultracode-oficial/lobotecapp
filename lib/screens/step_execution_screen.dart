import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signature/signature.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_bloc.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_event.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'equipment_detail_screen.dart';

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
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative o GPS (Localização) para efetuar o check-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'A permissão de localização foi negada permanentemente. Habilite nas configurações do aparelho.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!context.mounted) return;
      context.read<StepExecutionBloc>().add(
            PerformCheckInEvent(
              widget.etapaId,
              lat: position.latitude,
              lng: position.longitude,
            ),
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter coordenadas GPS: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSignatureDialog(BuildContext context) {
    _signatureController.clear();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Assinatura do Cliente',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Solicite que o cliente assine no quadro abaixo para confirmar a execução:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _signatureController,
                    height: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpar Assinatura'),
                  onPressed: () => _signatureController.clear(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_signatureController.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, assine antes de confirmar.'),
                    ),
                  );
                  return;
                }

                final imageBytes = await _signatureController.toPngBytes();
                if (imageBytes == null) return;

                final tempDir = Directory.systemTemp;
                final file = File(
                    '${tempDir.path}/assinatura_${widget.etapaId}_${DateTime.now().millisecondsSinceEpoch}.png');
                await file.writeAsBytes(imageBytes);

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);

                if (!context.mounted) return;
                context.read<StepExecutionBloc>().add(
                      UploadSignatureEvent(widget.etapaId, file.path),
                    );
              },
              child: const Text('Salvar Assinatura'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StepExecutionBloc, StepExecutionState>(
      listener: (context, state) {
        if (state is StepCheckInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in realizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          context
              .read<StepExecutionBloc>()
              .add(FetchStepDetailEvent(widget.etapaId));
        } else if (state is StepSignatureUploaded) {
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
        if (state is StepExecutionLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Atendimento')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        StepModel? step;
        if (state is StepExecutionLoaded) {
          step = state.step;
        } else if (state is StepCheckInSuccess) {
          step = state.step;
        } else if (state is StepSignatureUploaded) {
          step = state.step;
        }

        if (step != null) {
          final isCheckedIn = step.isCheckedIn;
          final isFinalized = step.isFinalized;
          final hasSignature = step.assinaturaUrl?.isNotEmpty == true;

          String statusLabel = 'AGUARDANDO CHECK-IN';
          Color statusColor = AppColors.warning;
          if (isFinalized) {
            statusLabel = 'ETAPA CONCLUÍDA';
            statusColor = AppColors.success;
          } else if (isCheckedIn) {
            statusLabel = 'ETAPA EM ANDAMENTO';
            statusColor = AppColors.primary;
          }

          final completedEquipments =
              step.equipamentos.where((e) => e.isFinalizado).length;

          return Scaffold(
            appBar: AppBar(
              title: Text(step.titulo ?? 'Etapa #${step.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                      if (isFinalized)
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Check-in Button
                  if (!isCheckedIn && !isFinalized) ...[
                    CustomButton(
                      text: 'EFETUAR CHECK-IN (GPS)',
                      onPressed: () => _handleCheckIn(context),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Equipments Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EQUIPAMENTOS ($completedEquipments/${step.equipamentos.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (isCheckedIn && !isFinalized)
                        const Text(
                          'Toque para executar',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (step.equipamentos.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Nenhum equipamento vinculado a esta etapa.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  ] else ...[
                    ...step.equipamentos.map(
                      (eq) => _buildEquipmentCard(
                        context,
                        eq,
                        isCheckedIn && !isFinalized,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: (isCheckedIn && !isFinalized)
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomButton(
                            text: hasSignature
                                ? 'ASSINATURA COLETADA'
                                : 'COLETAR ASSINATURA DO CLIENTE',
                            isPrimary: !hasSignature,
                            onPressed: () => _showSignatureDialog(context),
                          ),
                          const SizedBox(height: 8),
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
                  )
                : null,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Atendimento')),
          body: const SizedBox(),
        );
      },
    );
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    EquipmentModel eq,
    bool isActive,
  ) {
    String status = 'Aguardando Início';
    Color statusColor = AppColors.warning;
    String subtext = 'Toque para iniciar';
    Color subtextColor = AppColors.textSecondary;

    if (eq.isGeneric || eq.registroPendente) {
      status = 'Registro pendente';
      statusColor = AppColors.warning;
      subtext = 'Necessita cadastrar TAG/ficha';
      subtextColor = AppColors.error;
    } else if (eq.isFinalizado) {
      status = 'Finalizado';
      statusColor = AppColors.success;
      subtext = 'Equipamento concluído';
      subtextColor = AppColors.success;
    } else if (eq.isEmAndamento) {
      status = 'Em Andamento';
      statusColor = AppColors.primary;
      final completed = eq.tarefas.where((t) => t.isFeito).length;
      subtext = '$completed/${eq.tarefas.length} tarefas feitas';
    }

    return GestureDetector(
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
                    'Você precisa efetuar o CHECK-IN para acessar os equipamentos.',
                  ),
                ),
              );
            },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive ? Colors.white : AppColors.divider.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isActive
                ? (eq.isFinalizado ? AppColors.success : AppColors.border)
                : AppColors.border.withValues(alpha: 0.5),
            width: eq.isFinalizado ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(label: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtext,
                style: TextStyle(
                  color: subtextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    eq.marca?.isNotEmpty == true
                        ? '${eq.marca} ${eq.modelo ?? ''}'
                        : 'Marca não informada',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Tarefas: ${eq.tarefas.where((t) => t.isFeito).length}/${eq.tarefas.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
