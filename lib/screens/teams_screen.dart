import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/agenda/agenda_bloc.dart';
import '../features/execution/presentation/bloc/agenda/agenda_event.dart';
import '../features/execution/presentation/bloc/agenda/agenda_state.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/status_badge.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

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
      child: _TeamsView(dataInicio: dataInicio, dataFim: dataFim),
    );
  }
}

class _TeamsView extends StatelessWidget {
  final String dataInicio;
  final String dataFim;

  const _TeamsView({required this.dataInicio, required this.dataFim});

  void _copyContact(BuildContext context, String number, String name) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contato de $name copiado: $number'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactModal(BuildContext context, String name, String role, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phone,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                    tooltip: 'Copiar',
                    onPressed: () {
                      Navigator.pop(bottomContext);
                      _copyContact(context, phone, name);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Conversar no WhatsApp'),
                onPressed: () {
                  Navigator.pop(bottomContext);
                  _copyContact(context, phone, name);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Equipes & Parceiros',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar',
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
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AgendaBloc>().add(
                FetchAgendaEvent(
                  dataInicio: dataInicio,
                  dataFim: dataFim,
                ),
              );
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Banner da Equipe
            _buildTeamBanner(),
            const SizedBox(height: 16),

            // Card do Técnico (Você)
            _buildMyProfileSection(context),
            const SizedBox(height: 20),

            // Parceiros de campo nas Ordens de hoje
            _buildSectionHeader('Colegas em Missões Compartilhadas', Icons.people_outline),
            const SizedBox(height: 8),
            _buildColleaguesSection(context),
            const SizedBox(height: 20),

            // Central de Apoio e Coordenação
            _buildSectionHeader('Canais de Apoio Operacional', Icons.headset_mic_outlined),
            const SizedBox(height: 8),
            _buildSupportChannelsCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operações de Campo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Grupo LoboRJ • Climatização & Refrigeração',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'As duplas e equipes são alocadas conforme as etapas das Ordens de Serviço do dia.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProfileSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserEntity? user;
        if (state is AuthAuthenticated) {
          user = state.user;
        }

        final name = user?.name.isNotEmpty == true ? user!.name : 'Técnico';
        final role = user?.primaryRole.isNotEmpty == true ? user!.primaryRole : 'Técnico Residente';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: user?.photo != null && user!.photo!.isNotEmpty
                      ? NetworkImage(user.photo!)
                      : null,
                  child: user?.photo == null || user!.photo!.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VOCÊ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'Disponível / Em Rota de Campo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildColleaguesSection(BuildContext context) {
    return BlocBuilder<AgendaBloc, AgendaState>(
      builder: (context, state) {
        if (state is AgendaLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 12),
                    Text('Verificando parceiros alocados...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          );
        }

        List<StepModel> stepsWithColleagues = [];
        Map<String, List<String>> colleagueServices = {};

        if (state is AgendaLoaded) {
          stepsWithColleagues = state.steps.where((s) => s.colegas.isNotEmpty).toList();
          for (var step in stepsWithColleagues) {
            for (var col in step.colegas) {
              final osInfo = '${step.numeroOs ?? 'OS'} • ${step.titulo ?? 'Etapa'}';
              if (!colleagueServices.containsKey(col)) {
                colleagueServices[col] = [];
              }
              if (!colleagueServices[col]!.contains(osInfo)) {
                colleagueServices[col]!.add(osInfo);
              }
            }
          }
        }

        if (colleagueServices.isEmpty) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.person_pin_outlined, size: 42, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Operação Individual Hoje',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nenhum colega alocado nas suas etapas agendadas para o período. Suas ordens de serviço estão designadas para atendimento individual.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: colleagueServices.entries.map((entry) {
            final name = entry.key;
            final services = entry.value;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Parceiro Técnico em Campo',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: services.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.contact_phone, color: AppColors.primary),
                      tooltip: 'Ver Contato',
                      onPressed: () {
                        _showContactModal(context, name, 'Parceiro de Campo LoboRJ', '(21) 98000-0000');
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSupportChannelsCard(BuildContext context) {
    final supportChannels = [
      {
        'title': 'Coordenação & Despacho de Ordens',
        'subtitle': 'Apoio em rotas, clientes ausentes e reagendamentos',
        'phone': '(21) 3500-1001',
        'icon': Icons.alt_route,
        'badge': 'OPERACIONAL',
        'color': AppColors.primary,
      },
      {
        'title': 'Suporte Técnico de Engenharia',
        'subtitle': 'Códigos de erro, VRF, diagramas e carga de fluido',
        'phone': '(21) 3500-1002',
        'icon': Icons.engineering_outlined,
        'badge': 'ENGENHARIA',
        'color': AppColors.accent,
      },
      {
        'title': 'Almoxarifado & Reposição de Peças',
        'subtitle': 'Solicitação emergencial de peças e ferramentas',
        'phone': '(21) 3500-1003',
        'icon': Icons.inventory_2_outlined,
        'badge': 'PEÇAS',
        'color': AppColors.info,
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: supportChannels.asMap().entries.map((item) {
          final isLast = item.key == supportChannels.length - 1;
          final channel = item.value;

          return Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (channel['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(channel['icon'] as IconData, color: channel['color'] as Color, size: 20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel['title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    StatusBadge(
                      label: channel['badge'] as String,
                      color: channel['color'] as Color,
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      channel['subtitle'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      channel['phone'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
                  tooltip: 'Copiar número',
                  onPressed: () {
                    _copyContact(context, channel['phone'] as String, channel['title'] as String);
                  },
                ),
                onTap: () {
                  _showContactModal(
                    context,
                    channel['title'] as String,
                    channel['subtitle'] as String,
                    channel['phone'] as String,
                  );
                },
              ),
              if (!isLast) const Divider(height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}
