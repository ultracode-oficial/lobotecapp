import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_bloc.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_event.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'step_execution_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final int servicoId;

  const ServiceDetailScreen({super.key, required this.servicoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServiceOrdersBloc>(
      create: (_) => getIt<ServiceOrdersBloc>()
        ..add(FetchServiceOrderDetailEvent(servicoId)),
      child: _ServiceDetailView(servicoId: servicoId),
    );
  }
}

class _ServiceDetailView extends StatelessWidget {
  final int servicoId;

  const _ServiceDetailView({required this.servicoId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServiceOrdersBloc, ServiceOrdersState>(
      listener: (context, state) {
        if (state is ServiceOrderFinalizedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else if (state is ServiceOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ServiceOrdersLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ordem de Serviço')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ServiceOrderDetailLoaded) {
          final os = state.order;
          final isFinalized = os.status == 'FINALIZADO';

          return Scaffold(
            appBar: AppBar(
              title: Text(os.numeroOs),
              leading: const BackButton(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context
                        .read<ServiceOrdersBloc>()
                        .add(FetchServiceOrderDetailEvent(servicoId));
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
                        os.numeroOs,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusBadge(
                        label: os.status,
                        color: isFinalized
                            ? AppColors.success
                            : (os.status == 'EM_ANDAMENTO'
                                ? AppColors.primary
                                : AppColors.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    os.cliente?.nome ?? 'Cliente',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    os.cliente?.endereco ?? 'Endereço não informado',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'DESCRIÇÃO / REQUISITOS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    os.descricao?.isNotEmpty == true
                        ? os.descricao!
                        : (os.tipoServicoNome ?? 'Sem requisitos adicionais.'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ETAPAS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Concluídas: ${os.etapasClosed}/${os.etapasTotal}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (os.etapas.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Nenhuma etapa cadastrada para esta OS.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  ] else ...[
                    ...os.etapas.map((etapa) => _buildEtapaCard(context, etapa, isFinalized)),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: !isFinalized
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CustomButton(
                        text: 'FINALIZAR OS',
                        onPressed: os.podeFinalizarOs
                            ? () {
                                _confirmFinalizeOS(context, os.id);
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Conclua todas as etapas para poder finalizar a OS.',
                                    ),
                                  ),
                                );
                              },
                        isPrimary: os.podeFinalizarOs,
                      ),
                    ),
                  )
                : null,
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Ordem de Serviço')),
          body: const SizedBox(),
        );
      },
    );
  }

  Widget _buildEtapaCard(BuildContext context, StepModel etapa, bool isOsFinalized) {
    Color badgeColor = AppColors.warning;
    if (etapa.isFinalized) {
      badgeColor = AppColors.success;
    } else if (etapa.status == 'EM_ANDAMENTO') {
      badgeColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: isOsFinalized
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta ordem de serviço já foi finalizada!'),
                ),
              );
            }
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StepExecutionScreen(etapaId: etapa.id),
                ),
              ).then((_) {
                if (context.mounted) {
                  context
                      .read<ServiceOrdersBloc>()
                      .add(FetchServiceOrderDetailEvent(servicoId));
                }
              });
            },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: etapa.isFinalized ? AppColors.success : AppColors.border,
            width: etapa.isFinalized ? 2 : 1,
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
                  Text(
                    etapa.titulo ?? 'Etapa ${etapa.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    etapa.dataInicio ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(label: etapa.status, color: badgeColor),
                  Text(
                    'Equipamentos: ${etapa.equipamentos.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  void _confirmFinalizeOS(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Finalizar OS'),
        content: const Text(
          'Deseja realmente finalizar esta Ordem de Serviço? Todas as etapas já foram concluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ServiceOrdersBloc>().add(FinalizeServiceOrderEvent(id));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
