import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../features/execution/presentation/bloc/agenda/agenda_event.dart';
import '../features/execution/presentation/bloc/agenda/agenda_state.dart';
import '../widgets/status_badge.dart';
import 'step_execution_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dataInicio =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
    final nextMonth = DateTime(now.year, now.month + 1, 0);
    final dataFim =
        "${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-${nextMonth.day.toString().padLeft(2, '0')}";

    return BlocProvider<AgendaBloc>(
      create: (_) => getIt<AgendaBloc>()
        ..add(FetchAgendaEvent(dataInicio: dataInicio, dataFim: dataFim)),
      child: _AgendaView(dataInicio: dataInicio, dataFim: dataFim),
    );
  }
}

class _AgendaView extends StatelessWidget {
  final String dataInicio;
  final String dataFim;

  const _AgendaView({required this.dataInicio, required this.dataFim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AgendaBloc>().add(
                    FetchAgendaEvent(
                      dataInicio: dataInicio,
                      dataFim: dataFim,
                    ),
                  );
            },
          ),
        ],
      ),
      body: BlocBuilder<AgendaBloc, AgendaState>(
        builder: (context, state) {
          if (state is AgendaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgendaError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AgendaBloc>().add(
                              FetchAgendaEvent(
                                dataInicio: dataInicio,
                                dataFim: dataFim,
                              ),
                            );
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is AgendaLoaded) {
            final steps = state.steps;

            if (steps.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum atendimento agendado para o período.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Período: $dataInicio até $dataFim',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<AgendaBloc>().add(
                      FetchAgendaEvent(
                        dataInicio: dataInicio,
                        dataFim: dataFim,
                      ),
                    );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return _buildStepAgendaCard(context, step);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStepAgendaCard(BuildContext context, StepModel step) {
    Color badgeColor = AppColors.warning;
    if (step.isFinalized) {
      badgeColor = AppColors.success;
    } else if (step.status == 'EM_ANDAMENTO') {
      badgeColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StepExecutionScreen(etapaId: step.id),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<AgendaBloc>().add(
                    FetchAgendaEvent(
                      dataInicio: dataInicio,
                      dataFim: dataFim,
                    ),
                  );
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(label: step.status, color: badgeColor),
                  Text(
                    step.dataInicio ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.cliente?.nome ?? 'Cliente',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.cliente?.endereco ?? 'Endereço não informado',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    step.numeroOs ?? 'OS #${step.servicoId ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${step.equipamentos.length} equipamento(s)',
                    style: const TextStyle(
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
}
