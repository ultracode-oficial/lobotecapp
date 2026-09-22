import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../core/state.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/execution/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../features/execution/presentation/bloc/dashboard/dashboard_event.dart';
import '../features/execution/presentation/bloc/dashboard/dashboard_state.dart';
import '../widgets/status_badge.dart';
import 'agenda_screen.dart';
import 'service_orders_screen.dart';
import 'step_execution_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const _HomeContent(),
    const AgendaScreen(),
    const ServiceOrdersScreen(),
    const Scaffold(body: Center(child: Text('Equipes (Em breve)'))),
    const Scaffold(body: Center(child: Text('Perfil (Em breve)'))),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, _) {
        final state = AppState();
        _currentIndex = state.homeCurrentIndex;

        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                state.setHomeIndex(index);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Ordens'),
                BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Equipes'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => getIt<DashboardBloc>()..add(const FetchDashboardEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user = authState is AuthAuthenticated ? authState.user : null;
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user?.photo != null
                        ? NetworkImage(user!.photo!)
                        : null,
                    child: user?.photo == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Técnico',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.primaryRole ?? 'Campo',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
          ],
        ),
        drawer: const CustomDrawer(),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DashboardBloc>().add(const FetchDashboardEvent());
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is DashboardLoaded) {
              final dashboard = state.dashboard;
              final proximo = dashboard.proximoServico;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(const FetchDashboardEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indicadores de Hoje',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIndicatorCard(
                              'Ordens do Dia',
                              '${dashboard.ordensDoDia}',
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildIndicatorCard(
                              'Etapas Feitas',
                              '${dashboard.etapasFeitas}/${dashboard.etapasTotal}',
                              AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildIndicatorCard(
                        'Tempo Médio de Atendimento',
                        dashboard.tempoMedioMinutos != null
                            ? '${dashboard.tempoMedioMinutos} min'
                            : 'Sem histórico recente',
                        AppColors.textSecondary,
                      ),
                      const SizedBox(height: 28),

                      if (proximo != null) ...[
                        const Text(
                          'Próximo Atendimento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge(
                                      label: proximo.statusEtapa ?? 'AGUARDANDO',
                                      color: proximo.statusEtapa == 'EM_ANDAMENTO'
                                          ? AppColors.primary
                                          : AppColors.warning,
                                    ),
                                    Text(
                                      proximo.numeroOs ?? 'OS #${proximo.servicoId}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  proximo.cliente?.nome ?? 'Cliente',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  proximo.cliente?.endereco ?? 'Endereço não informado',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StepExecutionScreen(
                                            etapaId: proximo.etapaId,
                                          ),
                                        ),
                                      ).then((_) {
                                        if (context.mounted) {
                                          context
                                              .read<DashboardBloc>()
                                              .add(const FetchDashboardEvent());
                                        }
                                      });
                                    },
                                    child: Text(
                                      proximo.statusEtapa == 'EM_ANDAMENTO'
                                          ? 'Continuar Etapa'
                                          : 'Iniciar Atendimento',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Próximo Atendimento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 40, color: AppColors.success),
                                  SizedBox(height: 8),
                                  Text(
                                    'Nenhum atendimento pendente para hoje!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(height: 12),
                const Text(
                  'Grupo LoboRJ',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Técnico Mobile',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: AppColors.primary),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              AppState().setHomeIndex(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: AppColors.primary),
            title: const Text('Agenda'),
            onTap: () {
              Navigator.pop(context);
              AppState().setHomeIndex(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: AppColors.primary),
            title: const Text('Ordens de Serviço'),
            onTap: () {
              Navigator.pop(context);
              AppState().setHomeIndex(2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sair', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}
