import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../core/services/location_service.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/navigation_launcher.dart';
import '../features/execution/data/models/service_order_model.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/domain/usecases/step_execution_usecases.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_bloc.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_event.dart';
import '../features/execution/presentation/bloc/service_orders/service_orders_state.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_bloc.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'checkin_map_screen.dart';
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

class _ServiceDetailView extends StatefulWidget {
  final int servicoId;

  const _ServiceDetailView({required this.servicoId});

  @override
  State<_ServiceDetailView> createState() => _ServiceDetailViewState();
}

class _ServiceDetailViewState extends State<_ServiceDetailView> {
  double? _liveDistanceMeters;
  bool _isCheckingInDirect = false;
  StreamSubscription<Position>? _locSubscription;
  ServiceOrderModel? _currentOs;

  @override
  void initState() {
    super.initState();
    _subscribeLocation();
  }

  @override
  void dispose() {
    _locSubscription?.cancel();
    super.dispose();
  }

  void _subscribeLocation() {
    _updateLiveDistance();
    _locSubscription = LocationService.instance.positionStream.listen((_) {
      if (mounted) _updateLiveDistance();
    });
  }

  void _updateLiveDistance([ServiceOrderModel? os]) {
    if (os != null) _currentOs = os;
    final lat = _currentOs?.cliente?.lat;
    final lng = _currentOs?.cliente?.lng;
    if (lat != null && lng != null) {
      final dist = LocationService.instance.distanceTo(lat, lng);
      if (mounted && dist != _liveDistanceMeters) {
        setState(() => _liveDistanceMeters = dist);
      }
    }
  }

  void _openMapCheckIn(BuildContext context, StepModel step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<StepExecutionBloc>(
          create: (_) => getIt<StepExecutionBloc>(),
          child: CheckInMapScreen(step: step),
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        context
            .read<ServiceOrdersBloc>()
            .add(FetchServiceOrderDetailEvent(widget.servicoId));
      }
    });
  }

  Future<void> _performDirectCheckIn(BuildContext context, StepModel step) async {
    setState(() => _isCheckingInDirect = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isCheckingInDirect = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative o GPS (Localização) para efetuar o check-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isCheckingInDirect = false);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização negada pelo usuário.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isCheckingInDirect = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão negada permanentemente. Habilite nas configurações.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final pos = LocationService.instance.currentPosition ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );

      final clientLat = step.cliente?.lat;
      final clientLng = step.cliente?.lng;
      if (clientLat != null && clientLng != null) {
        final dist = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          clientLat,
          clientLng,
        );
        if (dist > 100) {
          setState(() {
            _isCheckingInDirect = false;
            _liveDistanceMeters = dist;
          });
          if (!context.mounted) return;
          final distStr = dist >= 1000
              ? '${(dist / 1000).toStringAsFixed(2)} km'
              : '${dist.toStringAsFixed(0)} m';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check-in bloqueado: Você está a $distStr do cliente. O raio máximo permitido é 100m.',
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      final result = await getIt<PerformCheckInUseCase>()(
        step.id,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      setState(() => _isCheckingInDirect = false);

      if (!context.mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in de presença realizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          context
              .read<ServiceOrdersBloc>()
              .add(FetchServiceOrderDetailEvent(widget.servicoId));
        },
      );
    } catch (e) {
      setState(() => _isCheckingInDirect = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao obter GPS: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

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
        } else if (state is ServiceOrderDetailLoaded) {
          _updateLiveDistance(state.order);
        }
      },
      builder: (context, state) {
        if (state is ServiceOrdersLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ordem de Serviço')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando dados da ordem...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ServiceOrderDetailLoaded) {
          final os = state.order;
          final isFinalized = os.status == 'FINALIZADO';
          final displayOs = (os.numeroOs.isNotEmpty &&
                  os.numeroOs != '#0' &&
                  os.numeroOs != '#null')
              ? os.numeroOs
              : 'OS #${widget.servicoId}';

          // Identificar a etapa ativa atual para o card de Check-in
          StepModel? activeEtapa;
          for (var e in os.etapas) {
            if (e.status == 'EM_ANDAMENTO') {
              activeEtapa = e;
              break;
            }
          }
          if (activeEtapa == null) {
            for (var e in os.etapas) {
              if (e.status == 'AGUARDANDO') {
                activeEtapa = e;
                break;
              }
            }
          }
          activeEtapa ??= os.etapas.isNotEmpty ? os.etapas.first : null;

          final double progressEtapas = os.etapasTotal > 0
              ? (os.etapasClosed / os.etapasTotal).clamp(0.0, 1.0)
              : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: Text(displayOs),
              leading: const BackButton(),
              actions: [
                if (!isFinalized && os.cliente?.lat != null && os.cliente?.lng != null)
                  IconButton(
                    icon: const Icon(Icons.navigation_rounded),
                    tooltip: 'Navegar com Waze / Maps',
                    onPressed: () => NavigationLauncher.showOptions(
                      context,
                      lat: os.cliente!.lat!,
                      lng: os.cliente!.lng!,
                      destinationName: os.cliente!.nome,
                      address: os.cliente!.endereco,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context
                        .read<ServiceOrdersBloc>()
                        .add(FetchServiceOrderDetailEvent(widget.servicoId));
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ServiceOrdersBloc>()
                    .add(FetchServiceOrderDetailEvent(widget.servicoId));
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. BANNER HERO LOBO RJ COM NAVEGAÇÃO
                  _buildHeroBanner(context, os, displayOs, isFinalized, activeEtapa),
                  const SizedBox(height: 16),

                  // 2. CARD DE CHECK-IN E RAIO DE 100M NA TELA DA OS (Como solicitado)
                  if (!isFinalized && activeEtapa != null)
                    _buildCheckInOsCard(context, os, activeEtapa),

                  const SizedBox(height: 20),

                  // 3. DESCRIÇÃO E REQUISITOS
                  _buildDescriptionCard(os),
                  const SizedBox(height: 24),

                  // 4. SEÇÃO DE ETAPAS COM DATAS FORMATADAS
                  _buildEtapasHeader(os, progressEtapas),
                  const SizedBox(height: 12),

                  if (os.etapas.isEmpty) ...[
                    const Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28.0),
                        child: Center(
                          child: Text(
                            'Nenhuma etapa cadastrada para esta OS.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...os.etapas.map(
                      (etapa) => _buildEtapaCard(context, etapa, isFinalized, activeEtapa),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            bottomNavigationBar: !isFinalized
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CustomButton(
                        text: 'FINALIZAR ORDEM DE SERVIÇO',
                        onPressed: os.podeFinalizarOs
                            ? () => _confirmFinalizeOS(context, os.id)
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

  Widget _buildHeroBanner(
    BuildContext context,
    ServiceOrderModel os,
    String displayOs,
    bool isFinalized,
    StepModel? activeEtapa,
  ) {
    final clienteNome = os.cliente?.nome ?? 'Cliente não informado';
    final endereco = os.cliente?.endereco ?? 'Endereço não informado';
    final tipoServico = os.tipoServicoNome?.isNotEmpty == true
        ? os.tipoServicoNome!
        : 'Atendimento Técnico';
    final dataAgendada = DateFormatter.formatDateTime(activeEtapa?.dataInicio);
    final tecnicos = activeEtapa?.colegas ?? [];

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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayOs,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: os.status,
                color: isFinalized
                    ? AppColors.success
                    : (os.status == 'EM_ANDAMENTO' ? AppColors.primary : AppColors.warning),
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
              fontSize: 19,
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

          // Endereço
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  endereco,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),

          // Data Agendada
          if (dataAgendada.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Agendado: $dataAgendada',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],

          // Colegas / Técnicos
          if (tecnicos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.engineering, size: 15, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Técnico(s): ${tecnicos.join(", ")}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          // BOTÕES DE NAVEGAÇÃO (WAZE / GOOGLE MAPS) - Apenas se a OS não estiver finalizada
          if (!isFinalized && os.cliente?.lat != null && os.cliente?.lng != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Navegar até o Local (Waze / Google Maps)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () => NavigationLauncher.showOptions(
                      context,
                      lat: os.cliente!.lat!,
                      lng: os.cliente!.lng!,
                      destinationName: clienteNome,
                      address: endereco,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckInOsCard(
    BuildContext context,
    ServiceOrderModel os,
    StepModel activeEtapa,
  ) {
    final isCheckedIn = activeEtapa.isCheckedIn;

    if (isCheckedIn) {
      final checkInFmt = DateFormatter.formatDateTime(activeEtapa.checkInAt);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: AppColors.success, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presença Confirmada no Local',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checkInFmt.isNotEmpty
                        ? 'Check-in realizado em $checkInFmt'
                        : 'Check-in validado com sucesso via GPS',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final distanceStr = _liveDistanceMeters != null
        ? (_liveDistanceMeters! >= 1000
            ? '${(_liveDistanceMeters! / 1000).toStringAsFixed(2)} km'
            : '${_liveDistanceMeters!.toStringAsFixed(0)} m')
        : null;

    final isInside100m = _liveDistanceMeters != null && _liveDistanceMeters! <= 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isInside100m ? AppColors.success : AppColors.warning.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validação de Check-in • ${activeEtapa.titulo ?? "Etapa #${activeEtapa.id}"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        distanceStr != null
                            ? 'Sua distância: $distanceStr (${isInside100m ? "Dentro do raio" : "Fora do raio"})'
                            : 'Validação georreferenciada obrigatória',
                        style: TextStyle(
                          color: isInside100m ? AppColors.success : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'O check-in libera o início das tarefas e a execução dos aparelhos da ${activeEtapa.titulo ?? "Etapa #${activeEtapa.id}"}.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 16),

            // Botão 1: Abrir Mapa Interativo (OSM com Raio de 100m)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.map_rounded, size: 20),
                label: Text(
                  'ABRIR MAPA & CHECK-IN (${(activeEtapa.titulo ?? "ETAPA #${activeEtapa.id}").toUpperCase()})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _openMapCheckIn(context, activeEtapa),
              ),
            ),
            const SizedBox(height: 8),

            // Botão 2: Check-in Direto no Local (Apenas habilitado dentro dos 100m)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isInside100m ? AppColors.success : Colors.grey.shade500,
                  side: BorderSide(
                    color: isInside100m ? AppColors.success : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isCheckingInDirect
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isInside100m ? Icons.check_circle_outline : Icons.lock_outline,
                        size: 18,
                      ),
                label: Text(
                  _isCheckingInDirect
                      ? 'VALIDANDO GPS...'
                      : (isInside100m
                          ? 'Confirmar Presença Direta (No Local)'
                          : 'Presença Direta Bloqueada (Fora dos 100m)'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                onPressed: (isInside100m && !_isCheckingInDirect)
                    ? () => _performDirectCheckIn(context, activeEtapa)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(ServiceOrderModel os) {
    final descricao = os.descricao?.isNotEmpty == true
        ? os.descricao!
        : (os.tipoServicoNome ?? 'Sem requisitos adicionais.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DESCRIÇÃO / REQUISITOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            descricao,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEtapasHeader(ServiceOrderModel os, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ETAPAS DA ORDEM',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Concluídas: ${os.etapasClosed}/${os.etapasTotal}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
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

  Widget _buildEtapaCard(
    BuildContext context,
    StepModel etapa,
    bool isOsFinalized,
    StepModel? activeEtapa,
  ) {
    Color badgeColor = AppColors.warning;
    String actionLabel = 'Aguardando Check-in';
    IconData actionIcon = Icons.hourglass_top_rounded;

    if (etapa.isFinalized) {
      badgeColor = AppColors.success;
      actionLabel = 'Atendimento Concluído';
      actionIcon = Icons.check_circle_outline;
    } else if (etapa.status == 'EM_ANDAMENTO') {
      badgeColor = AppColors.primary;
      actionLabel = 'Toque para Executar Equipamentos';
      actionIcon = Icons.play_arrow_rounded;
    }

    // FORMATAÇÃO CORRETA DA DATA EM FORMATO BRASILEIRO
    final dataInicioFmt = DateFormatter.formatDateTime(etapa.dataInicio);

    final totalEquipamentos = (etapa.equipamentosTotal != null && etapa.equipamentosTotal! > 0)
        ? etapa.equipamentosTotal!
        : etapa.equipamentos.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: etapa.isFinalized
              ? AppColors.success
              : (etapa.status == 'EM_ANDAMENTO'
                  ? AppColors.primary
                  : AppColors.border),
          width: (etapa.isFinalized || etapa.status == 'EM_ANDAMENTO') ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                        .add(FetchServiceOrderDetailEvent(widget.servicoId));
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
                  Expanded(
                    child: Text(
                      etapa.titulo ?? 'Etapa ${etapa.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (dataInicioFmt.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dataInicioFmt,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(label: etapa.status, color: badgeColor),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$totalEquipamentos Equipamento(s)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, size: 16, color: badgeColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            actionLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.textSecondary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar OS', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Deseja realmente finalizar esta Ordem de Serviço? Todas as etapas já foram concluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ServiceOrdersBloc>().add(FinalizeServiceOrderEvent(id));
            },
            child: const Text('Confirmar e Finalizar'),
          ),
        ],
      ),
    );
  }
}
