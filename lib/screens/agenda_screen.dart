import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/navigation_launcher.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../features/execution/presentation/bloc/agenda/agenda_event.dart';
import '../features/execution/presentation/bloc/agenda/agenda_state.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/status_badge.dart';
import 'step_execution_screen.dart';

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dataInicio = "${now.year}-${now.month.toString().padLeft(2, '0')}-01";
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final dataFim =
        "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";

    return BlocProvider<AgendaBloc>(
      create: (_) => getIt<AgendaBloc>()
        ..add(FetchAgendaEvent(dataInicio: dataInicio, dataFim: dataFim)),
      child: const _AgendaCalendarView(),
    );
  }
}

class _AgendaCalendarView extends StatefulWidget {
  const _AgendaCalendarView();

  @override
  State<_AgendaCalendarView> createState() => _AgendaCalendarViewState();
}

class _AgendaCalendarViewState extends State<_AgendaCalendarView> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  bool _isMonthExpanded = true;

  static const List<String> _meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _diasSemana = [
    'DOM',
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
  ];
  static const List<String> _diasSemanaCompleto = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];



  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _fetchMonth(DateTime month) {
    final start = "${month.year}-${month.month.toString().padLeft(2, '0')}-01";
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final end =
        "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";

    context.read<AgendaBloc>().add(
          FetchAgendaEvent(dataInicio: start, dataFim: end),
        );
  }

  void _changeMonth(int offset) {
    final newMonth =
        DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    setState(() {
      _currentMonth = newMonth;
      _selectedDate = null; // Mostrar todos ao trocar de mês
    });
    _fetchMonth(newMonth);
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final todayMonth = DateTime(now.year, now.month, 1);
    final needFetch = todayMonth.year != _currentMonth.year ||
        todayMonth.month != _currentMonth.month;

    setState(() {
      _currentMonth = todayMonth;
      _selectedDate = DateTime(now.year, now.month, now.day);
    });

    if (needFetch) {
      _fetchMonth(todayMonth);
    }
  }

  DateTime? _parseStepDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      try {
        final p = iso.split('T')[0].split('-');
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) {
        return null;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<int, List<StepModel>> _groupStepsByDay(
      int year, int month, List<StepModel> steps) {
    final map = <int, List<StepModel>>{};
    for (final s in steps) {
      final dt = _parseStepDate(s.dataInicio);
      if (dt != null && dt.year == year && dt.month == month) {
        map.putIfAbsent(dt.day, () => []).add(s);
      }
    }
    return map;
  }

  String _formatTimeRange(String? startIso, String? endIso) {
    final startDt = _parseStepDate(startIso);
    final endDt = _parseStepDate(endIso);
    if (startDt == null) return 'Horário a definir';
    final sHour = startDt.hour.toString().padLeft(2, '0');
    final sMin = startDt.minute.toString().padLeft(2, '0');
    if (endDt == null) return '$sHour:$sMin';
    final eHour = endDt.hour.toString().padLeft(2, '0');
    final eMin = endDt.minute.toString().padLeft(2, '0');
    return '$sHour:$sMin às $eHour:$eMin';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Minha Agenda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Botão "Hoje"
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.today, size: 18, color: Colors.white),
            label: const Text(
              'Hoje',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _jumpToToday,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: () => _fetchMonth(_currentMonth),
          ),
        ],
      ),
      body: BlocBuilder<AgendaBloc, AgendaState>(
        builder: (context, state) {
          if (state is AgendaLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando calendário de atendimentos...',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          if (state is AgendaError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 52, color: AppColors.error),
                    const SizedBox(height: 14),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      onPressed: () => _fetchMonth(_currentMonth),
                    ),
                  ],
                ),
              ),
            );
          }

          final steps = (state is AgendaLoaded) ? state.steps : <StepModel>[];
          final stepsByDay = _groupStepsByDay(
            _currentMonth.year,
            _currentMonth.month,
            steps,
          );

          // Filtrar os steps para a listagem
          List<StepModel> filteredSteps;
          if (_selectedDate != null) {
            filteredSteps = steps.where((s) {
              final dt = _parseStepDate(s.dataInicio);
              return dt != null && _isSameDay(dt, _selectedDate!);
            }).toList();
          } else {
            filteredSteps = List.from(steps);
          }

          // Ordenar por data/hora
          filteredSteps.sort((a, b) {
            final dtA = _parseStepDate(a.dataInicio) ?? DateTime(2000);
            final dtB = _parseStepDate(b.dataInicio) ?? DateTime(2000);
            return dtA.compareTo(dtB);
          });

          return RefreshIndicator(
            onRefresh: () async {
              _fetchMonth(_currentMonth);
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. CARD PRINCIPAL DO CALENDÁRIO
                _buildCalendarCard(now, stepsByDay, steps.length),

                const SizedBox(height: 18),

                // 2. BARRA DE FILTRO E SELEÇÃO DE DATA
                _buildDateSelectionHeader(filteredSteps.length, steps.length),

                const SizedBox(height: 12),

                // 3. LISTA DE ATENDIMENTOS DA DATA OU DO MÊS
                if (filteredSteps.isEmpty)
                  _buildEmptyState()
                else
                  ...filteredSteps
                      .map((step) => _buildAgendaStepCard(context, step)),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // WIDGET DO CALENDÁRIO COMPLETO
  // ==========================================
  Widget _buildCalendarCard(
    DateTime now,
    Map<int, List<StepModel>> stepsByDay,
    int totalMonthSteps,
  ) {
    final monthName = _meses[_currentMonth.month - 1];
    final year = _currentMonth.year;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Topo do Calendário: Navegação de Mês + Ano
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textPrimary),
                  tooltip: 'Mês anterior',
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$monthName $year',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        totalMonthSteps > 0
                            ? '$totalMonthSteps atendimento(s) no mês'
                            : 'Nenhum agendamento no mês',
                        style: TextStyle(
                          fontSize: 11,
                          color: totalMonthSteps > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textPrimary),
                  tooltip: 'Próximo mês',
                  onPressed: () => _changeMonth(1),
                ),
                // Botão de expandir / recolher visão de mês
                IconButton(
                  icon: Icon(
                    _isMonthExpanded
                        ? Icons.calendar_view_week
                        : Icons.calendar_view_month,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: _isMonthExpanded
                      ? 'Visão semanal'
                      : 'Visão mensal completa',
                  onPressed: () {
                    setState(() => _isMonthExpanded = !_isMonthExpanded);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Cabeçalho dos Dias da Semana (DOM, SEG, TER...)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: _diasSemana.map((dia) {
                final isWeekend = dia == 'DOM' || dia == 'SÁB';
                return Expanded(
                  child: Center(
                    child: Text(
                      dia,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isWeekend
                            ? Colors.grey.shade400
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Grade de Dias (Mês ou Semana)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: _isMonthExpanded
                ? _buildMonthGrid(now, stepsByDay)
                : _buildWeekRow(now, stepsByDay),
          ),

          // Legenda do Calendário
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 6,
              children: [
                _buildLegendItem(AppColors.success, 'Concluído'),
                _buildLegendItem(AppColors.primary, 'Em Andamento'),
                _buildLegendItem(AppColors.warning, 'Aguardando'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // Grade de 30/31 dias do mês
  Widget _buildMonthGrid(
      DateTime now, Map<int, List<StepModel>> stepsByDay) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final totalDays = lastDay.day;

    // Domingo = 0, Segunda = 1, ..., Sábado = 6
    final firstWeekday = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final totalCells = firstWeekday + totalDays;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            if (cellIndex < firstWeekday ||
                cellIndex >= firstWeekday + totalDays) {
              return const Expanded(child: SizedBox(height: 42));
            }

            final day = cellIndex - firstWeekday + 1;
            final cellDate =
                DateTime(_currentMonth.year, _currentMonth.month, day);
            final isToday = _isSameDay(cellDate, now);
            final isSelected =
                _selectedDate != null && _isSameDay(cellDate, _selectedDate!);
            final daySteps = stepsByDay[day] ?? [];

            return Expanded(
              child: _buildDayCell(
                day: day,
                cellDate: cellDate,
                isToday: isToday,
                isSelected: isSelected,
                daySteps: daySteps,
              ),
            );
          }),
        );
      }),
    );
  }

  // Visão em tira da semana atual
  Widget _buildWeekRow(
      DateTime now, Map<int, List<StepModel>> stepsByDay) {
    final anchor = _selectedDate ?? now;
    // Encontrar o domingo da semana de anchor
    final sundayOffset = anchor.weekday == 7 ? 0 : anchor.weekday;
    final sunday = anchor.subtract(Duration(days: sundayOffset));

    return Row(
      children: List.generate(7, (i) {
        final cellDate = sunday.add(Duration(days: i));
        final isCurrentMonth = cellDate.month == _currentMonth.month &&
            cellDate.year == _currentMonth.year;
        final isToday = _isSameDay(cellDate, now);
        final isSelected =
            _selectedDate != null && _isSameDay(cellDate, _selectedDate!);
        final daySteps = isCurrentMonth ? (stepsByDay[cellDate.day] ?? []) : <StepModel>[];

        return Expanded(
          child: _buildDayCell(
            day: cellDate.day,
            cellDate: cellDate,
            isToday: isToday,
            isSelected: isSelected,
            daySteps: daySteps,
            isOutsideMonth: !isCurrentMonth,
          ),
        );
      }),
    );
  }

  // Célula de cada dia
  Widget _buildDayCell({
    required int day,
    required DateTime cellDate,
    required bool isToday,
    required bool isSelected,
    required List<StepModel> daySteps,
    bool isOutsideMonth = false,
  }) {
    Color? dotColor;
    if (daySteps.isNotEmpty) {
      if (daySteps.every((s) => s.isFinalized)) {
        dotColor = AppColors.success;
      } else if (daySteps.any((s) => s.status == 'EM_ANDAMENTO')) {
        dotColor = AppColors.primary;
      } else {
        dotColor = AppColors.warning;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedDate = null; // Toggle: destecliona para ver tudo
          } else {
            _selectedDate = cellDate;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isToday
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isSelected)
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isOutsideMonth
                        ? Colors.grey.shade400
                        : (isToday
                            ? AppColors.primary
                            : AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 2),
            if (dotColor != null)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BARRA DE SELEÇÃO E FILTRO
  // ==========================================
  Widget _buildDateSelectionHeader(int filteredCount, int totalMonthCount) {
    if (_selectedDate != null) {
      final diaSemana = _diasSemanaCompleto[_selectedDate!.weekday - 1];
      final dia = _selectedDate!.day.toString().padLeft(2, '0');
      final mes = _meses[_selectedDate!.month - 1];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$diaSemana, $dia de $mes',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  filteredCount > 0
                      ? '$filteredCount atendimento(s) programado(s)'
                      : 'Sem atendimentos para este dia',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.clear, size: 14, color: AppColors.primary),
            label: Text(
              'Ver Mês ($totalMonthCount)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            onPressed: () => setState(() => _selectedDate = null),
          ),
        ],
      );
    }

    final mes = _meses[_currentMonth.month - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Todos os Atendimentos de $mes',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$totalMonthCount no mês',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // CARD DETALHADO DO ATENDIMENTO / ETAPA
  // ==========================================
  Widget _buildAgendaStepCard(BuildContext context, StepModel step) {
    Color badgeColor = AppColors.warning;
    if (step.isFinalized) {
      badgeColor = AppColors.success;
    } else if (step.status == 'EM_ANDAMENTO') {
      badgeColor = AppColors.primary;
    }

    final timeRange =
        _formatTimeRange(step.dataInicio, step.dataFim);
    final dateFormatted = DateFormatter.formatDate(step.dataInicio);
    final clienteNome = step.cliente?.nome ?? 'Cliente não informado';
    final endereco = step.cliente?.endereco ?? 'Endereço não informado';
    final totalEquip = (step.equipamentosTotal != null && step.equipamentosTotal! > 0)
        ? step.equipamentosTotal!
        : step.equipamentos.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: step.status == 'EM_ANDAMENTO'
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: step.status == 'EM_ANDAMENTO' ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha Superior: Status + Data + Horário
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: step.status, color: badgeColor),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$dateFormatted • $timeRange',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Identificação do Cliente e Etapa
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clienteNome,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.titulo ?? 'Etapa ${step.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Endereço
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    endereco,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Rodapé com OS, Aparelhos e Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    step.numeroOs ?? 'OS #${step.servicoId ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.ac_unit,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$totalEquip aparelho(s)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // BOTÕES DE AÇÃO RÁPIDA (EXECUTAR E NAVEGAR)
            Row(
              children: [
                // Botão Navegar com Waze / Google Maps (apenas se não estiver finalizado)
                if (!step.isFinalized && step.cliente?.lat != null && step.cliente?.lng != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.navigation_outlined,
                          size: 16, color: AppColors.primary),
                      label: const Text(
                        'Navegar',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      onPressed: () => NavigationLauncher.showOptions(
                        context,
                        lat: step.cliente!.lat!,
                        lng: step.cliente!.lng!,
                        destinationName: clienteNome,
                        address: endereco,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Botão Abrir Atendimento
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.isFinalized
                          ? Colors.grey.shade700
                          : (step.status == 'EM_ANDAMENTO'
                              ? AppColors.primary
                              : AppColors.accent),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      step.isFinalized
                          ? Icons.check_circle_outline
                          : (step.status == 'EM_ANDAMENTO'
                              ? Icons.play_arrow
                              : Icons.login),
                      size: 18,
                    ),
                    label: Text(
                      step.isFinalized
                          ? 'Ver Atendimento'
                          : (step.status == 'EM_ANDAMENTO'
                              ? 'Continuar Atendimento'
                              : 'Abrir Atendimento'),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StepExecutionScreen(etapaId: step.id),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          _fetchMonth(_currentMonth);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ESTADO VAZIO
  // ==========================================
  Widget _buildEmptyState() {
    final hasSelection = _selectedDate != null;
    final dateStr = hasSelection
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
        : _meses[_currentMonth.month - 1];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available,
                    size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'Nenhum atendimento em $dateStr',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasSelection
                    ? 'Você não possui etapas de OS agendadas para esta data.'
                    : 'Nenhum serviço agendado para o mês selecionado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (hasSelection) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Exibir todos os atendimentos do mês'),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
