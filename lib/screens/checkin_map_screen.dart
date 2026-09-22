import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/colors.dart';
import '../core/services/location_service.dart';
import '../features/execution/data/models/step_model.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_bloc.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_event.dart';
import '../features/execution/presentation/bloc/step_execution/step_execution_state.dart';

class CheckInMapScreen extends StatefulWidget {
  final StepModel step;

  const CheckInMapScreen({super.key, required this.step});

  @override
  State<CheckInMapScreen> createState() => _CheckInMapScreenState();
}

class _CheckInMapScreenState extends State<CheckInMapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;

  Position? _currentPosition;
  double? _distanceMeters;
  bool _isLoadingGps = true;
  bool _isCheckingIn = false;
  String? _gpsError;

  static const double _maxAllowedRadius = 100.0;

  double get _clientLat => widget.step.cliente?.lat ?? 0.0;
  double get _clientLng => widget.step.cliente?.lng ?? 0.0;
  bool get _hasClientCoordinates => _clientLat != 0.0 && _clientLng != 0.0;

  @override
  void initState() {
    super.initState();
    _subscribeLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _subscribeLocation() {
    final locService = LocationService.instance;
    final cached = locService.currentPosition;

    if (cached != null) {
      _updatePosition(cached);
      _isLoadingGps = false;
    } else {
      _isLoadingGps = true;
      locService.startTracking().then((success) {
        if (!success && mounted) {
          setState(() {
            _isLoadingGps = false;
            _gpsError = locService.lastError ?? 'Não foi possível obter sinal de GPS.';
          });
        }
      });
    }

    _positionStream = locService.positionStream.listen((pos) {
      if (mounted) {
        _updatePosition(pos);
      }
    });

    if (locService.lastError != null && cached == null) {
      _gpsError = locService.lastError;
      _isLoadingGps = false;
    }
  }

  Future<void> _refreshGps() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });
    await LocationService.instance.startTracking();
    final pos = LocationService.instance.currentPosition;
    if (pos != null && mounted) {
      _updatePosition(pos);
    } else if (mounted) {
      setState(() {
        _isLoadingGps = false;
        _gpsError =
            LocationService.instance.lastError ?? 'Erro ao obter sinal de GPS.';
      });
    }
  }

  void _updatePosition(Position pos) {
    double? dist;
    if (_hasClientCoordinates) {
      dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _clientLat,
        _clientLng,
      );
    }

    setState(() {
      _currentPosition = pos;
      _distanceMeters = dist;
      _isLoadingGps = false;
    });
  }

  void _centerOnClient() {
    if (_hasClientCoordinates) {
      _mapController.move(LatLng(_clientLat, _clientLng), 17.0);
    }
  }

  void _centerOnTechnician() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        17.0,
      );
    }
  }

  void _fitBoth() {
    if (_hasClientCoordinates && _currentPosition != null) {
      final bounds = LatLngBounds(
        LatLng(_clientLat, _clientLng),
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      );
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
      );
    }
  }

  Future<void> _performCheckIn() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguardando sinal de GPS para registrar o check-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final bool isInside =
        _distanceMeters != null && _distanceMeters! <= _maxAllowedRadius;
    if (!isInside) {
      final distText = _distanceMeters != null
          ? (_distanceMeters! >= 1000
              ? '${(_distanceMeters! / 1000).toStringAsFixed(2)} km'
              : '${_distanceMeters!.toStringAsFixed(0)} m')
          : 'desconhecida';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in bloqueado: Você está a $distText do local. O raio máximo permitido é 100m.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCheckingIn = true);

    context.read<StepExecutionBloc>().add(
      PerformCheckInEvent(
        widget.step.id,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientLatLng = LatLng(_clientLat, _clientLng);
    final techLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    final bool isInsideRadius =
        _distanceMeters != null && _distanceMeters! <= _maxAllowedRadius;

    return BlocListener<StepExecutionBloc, StepExecutionState>(
      listener: (context, state) {
        if (state is StepCheckInSuccess) {
          setState(() => _isCheckingIn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in de presença realizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is StepExecutionError) {
          setState(() => _isCheckingIn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validação de Check-in GPS'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recarregar GPS',
              onPressed: _refreshGps,
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. MAPA INTERATIVO OPENSTREETMAP (OSM)
            if (_hasClientCoordinates)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: clientLatLng,
                  initialZoom: 16.5,
                  minZoom: 10,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.arcondicionado',
                  ),

                  // Círculo de 100 metros de Raio ao redor do Cliente
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: clientLatLng,
                        radius: _maxAllowedRadius,
                        useRadiusInMeter: true,
                        color: isInsideRadius
                            ? AppColors.success.withValues(alpha: 0.18)
                            : AppColors.primary.withValues(alpha: 0.16),
                        borderColor: isInsideRadius
                            ? AppColors.success
                            : AppColors.primary,
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),

                  // Linha conectando técnico ao cliente (se ambos disponíveis)
                  if (techLatLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [techLatLng, clientLatLng],
                          color: isInsideRadius
                              ? AppColors.success
                              : AppColors.warning,
                          strokeWidth: 2.5,
                          pattern: StrokePattern.dashed(segments: const [8, 5]),
                        ),
                      ],
                    ),

                  // Marcadores (Cliente e Técnico)
                  MarkerLayer(
                    markers: [
                      // Marcador do Cliente
                      Marker(
                        point: clientLatLng,
                        width: 52,
                        height: 52,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Marcador do Técnico (Sua Localização)
                      if (techLatLng != null)
                        Marker(
                          point: techLatLng,
                          width: 52,
                          height: 52,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isInsideRadius
                                      ? AppColors.success
                                      : AppColors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isInsideRadius
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'As coordenadas do cliente não foram informadas para esta Ordem de Serviço.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),

            // 2. BOTÕES DE CONTROLE DO MAPA (Topo Direito)
            if (_hasClientCoordinates)
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'center_client',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      tooltip: 'Centralizar no Cliente',
                      onPressed: _centerOnClient,
                      child: const Icon(Icons.business_outlined),
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition != null) ...[
                      FloatingActionButton.small(
                        heroTag: 'center_tech',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        tooltip: 'Minha Posição',
                        onPressed: _centerOnTechnician,
                        child: const Icon(Icons.my_location_rounded),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'fit_both',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        tooltip: 'Ver Ambos',
                        onPressed: _fitBoth,
                        child: const Icon(Icons.zoom_out_map_rounded),
                      ),
                    ],
                  ],
                ),
              ),

            // 3. CARD INFORMATIVO SUPERIOR (Distância e Status)
            Positioned(
              top: 16,
              left: 16,
              right: _hasClientCoordinates ? 74 : 16,
              child: _buildDistanceStatusHeader(isInsideRadius),
            ),

            // 4. PAINEL INFERIOR FLUTUANTE (Dados e Ação de Check-in)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomCheckInPanel(isInsideRadius),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceStatusHeader(bool isInside) {
    if (_isLoadingGps) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Obtendo GPS...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (_gpsError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          _gpsError!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final distanceStr = _distanceMeters != null
        ? (_distanceMeters! >= 1000
              ? '${(_distanceMeters! / 1000).toStringAsFixed(2)} km'
              : '${_distanceMeters!.toStringAsFixed(0)} m')
        : '--';

    final badgeColor = isInside ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInside ? Icons.check_circle_rounded : Icons.radar_rounded,
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Distância: $distanceStr',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: badgeColor,
                  ),
                ),
                Text(
                  isInside
                      ? 'Dentro do raio de 100m'
                      : 'Raio máx. permitido: 100m',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckInPanel(bool isInsideRadius) {
    final cliente = widget.step.cliente;
    final clienteNome = cliente?.nome ?? 'Cliente';
    final endereco = cliente?.endereco ?? 'Endereço não informado';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puxador central
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Informações do Local
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clienteNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        endereco,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aviso de proximidade
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isInsideRadius
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isInsideRadius ? Icons.verified : Icons.info_outline,
                    size: 16,
                    color: isInsideRadius
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isInsideRadius
                          ? 'Localização validada! Você está dentro do raio permitido de 100m.'
                          : 'Aproxime-se a menos de 100m do cliente para validar o check-in.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isInsideRadius
                            ? AppColors.success
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botão Principal de Check-in
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInsideRadius
                      ? AppColors.success
                      : Colors.grey.shade300,
                  foregroundColor: isInsideRadius
                      ? Colors.white
                      : Colors.grey.shade600,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: isInsideRadius ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isCheckingIn
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isInsideRadius
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isCheckingIn
                      ? 'REGISTRANDO CHECK-IN...'
                      : (isInsideRadius
                            ? 'CONFIRMAR CHECK-IN AGORA'
                            : 'FORA DO RAIO (Aproxime-se a menos de 100m)'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: (isInsideRadius && !_isCheckingIn)
                    ? _performCheckIn
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
