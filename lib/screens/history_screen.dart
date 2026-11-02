import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../core/utils/date_formatter.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/history/history_bloc.dart';
import '../features/execution/presentation/bloc/history/history_event.dart';
import '../features/execution/presentation/bloc/history/history_state.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/status_badge.dart';
import 'step_execution_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (_) => getIt<HistoryBloc>()..add(const FetchHistoryEvent()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final TextEditingController _qController = TextEditingController();
  Timer? _debounce;
  DateTime? _selectedDate;
  bool _hasActiveFilters = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _qController.dispose();
    super.dispose();
  }

  String? get _dataParam {
    final d = _selectedDate;
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String get _dateLabel {
    final d = _selectedDate;
    if (d == null) return 'Data';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  void _fetch() {
    final q = _qController.text.trim();
    setState(() {
      _hasActiveFilters = q.isNotEmpty || _selectedDate != null;
    });
    context.read<HistoryBloc>().add(
          FetchHistoryEvent(
            q: q.isEmpty ? null : q,
            data: _dataParam,
          ),
        );
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetch);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Filtrar por data',
      cancelText: 'Cancelar',
      confirmText: 'Filtrar',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    _fetch();
  }

  void _clearFilters() {
    _debounce?.cancel();
    _qController.clear();
    setState(() {
      _selectedDate = null;
      _hasActiveFilters = false;
    });
    context.read<HistoryBloc>().add(const FetchHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Histórico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                if (state is HistoryLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando histórico...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is HistoryError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 52,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar Novamente'),
                            onPressed: _fetch,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is HistoryLoaded) {
                  final steps = state.steps;

                  return RefreshIndicator(
                    onRefresh: () async {
                      _fetch();
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        _buildBanner(steps.length),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _hasActiveFilters
                                  ? 'Resultados do filtro'
                                  : 'Atendimentos finalizados',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${steps.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (steps.isEmpty)
                          _buildEmpty()
                        else
                          ...steps.map((step) => _buildCard(context, step)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasDate = _selectedDate != null;

    return Material(
      color: Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qController,
                    onChanged: _onQueryChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      _debounce?.cancel();
                      _fetch();
                    },
                    decoration: InputDecoration(
                      hintText: 'Cliente ou nº da OS',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        hasDate ? AppColors.primary : AppColors.textPrimary,
                    side: BorderSide(
                      color: hasDate ? AppColors.primary : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 16),
                  label: const Text('Limpar filtros'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(int total) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu histórico de campo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasActiveFilters
                      ? (total == 0
                          ? 'Nenhum atendimento para este filtro.'
                          : '$total resultado(s) encontrado(s).')
                      : (total == 0
                          ? 'Nenhum atendimento finalizado ainda.'
                          : '$total atendimento(s) concluído(s).'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                _hasActiveFilters ? Icons.search_off : Icons.history_toggle_off,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _hasActiveFilters
                    ? 'Nenhum resultado para o filtro'
                    : 'Nenhum atendimento no histórico',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _hasActiveFilters
                    ? 'Ajuste cliente, OS ou data, ou limpe os filtros.'
                    : 'Quando você finalizar etapas, elas aparecem aqui.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, StepModel step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
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
            if (context.mounted) _fetch();
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
                  const StatusBadge(
                    label: 'FINALIZADO',
                    color: AppColors.success,
                  ),
                  if (step.numeroOs != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.numeroOs!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.cliente?.nome ?? 'Cliente',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  step.label,
                  if (step.tipoServicoNome != null &&
                      step.tipoServicoNome!.isNotEmpty)
                    step.tipoServicoNome!,
                ].join(' • '),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatFullDateTime(
                      step.dataFim ?? step.dataInicio,
                    ),
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
