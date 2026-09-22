import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Serviço singleton responsável por rastrear a localização do técnico
/// de forma contínua em segundo plano no app (a cada 10s e por deslocamento).
///
/// Mantém a posição sempre em cache para que ao abrir qualquer tela (mapa, OS, check-in),
/// as coordenadas estejam disponíveis instantaneamente sem tela de espera.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  static LocationService get instance => _instance;

  LocationService._internal();

  Position? _currentPosition;

  /// Última posição válida obtida e mantida em memória (acesso síncrono instantâneo)
  Position? get currentPosition => _currentPosition;

  /// Notificador reativo para widgets observarem mudanças sem gerenciar streams
  final ValueNotifier<Position?> positionNotifier = ValueNotifier<Position?>(null);

  final StreamController<Position> _positionStreamController =
      StreamController<Position>.broadcast();

  /// Stream com emissões em tempo real da posição
  Stream<Position> get positionStream => _positionStreamController.stream;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicTimer;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastUpdateTime;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Inicia o monitoramento contínuo da localização.
  /// Atualiza por deslocamento (distanceFilter: 5m) E a cada 10 segundos via Timer.
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _lastError = 'Serviço de localização desativado no aparelho.';
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastError = 'Permissão de localização negada pelo usuário.';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _lastError = 'Permissão negada permanentemente. Habilite nas configurações.';
        return false;
      }

      _isTracking = true;
      _lastError = null;

      // 1. Obter última posição conhecida imediatamente (0ms de espera!)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _updatePosition(lastKnown);
        }
      } catch (_) {}

      // 2. Obter fix atual em alta precisão de imediato
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        _updatePosition(current);
      } catch (_) {}

      // 3. Ouvir Stream contínuo do Geolocator (atualiza quando há movimento >= 5m)
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) => _updatePosition(pos),
        onError: (err) {
          _lastError = err.toString();
        },
      );

      // 4. Timer periódico a cada 10 segundos (mantém atualização constante mesmo parado)
      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        await _pollFreshPosition();
      });

      return true;
    } catch (e) {
      _lastError = e.toString();
      _isTracking = false;
      return false;
    }
  }

  Future<void> _pollFreshPosition() async {
    if (!_isTracking) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      _updatePosition(pos);
    } catch (_) {}
  }

  void _updatePosition(Position pos) {
    _currentPosition = pos;
    _lastUpdateTime = DateTime.now();
    positionNotifier.value = pos;
    if (!_positionStreamController.isClosed) {
      _positionStreamController.add(pos);
    }
  }

  /// Calcula a distância em metros até o ponto alvo informado
  double? distanceTo(double? targetLat, double? targetLng) {
    if (_currentPosition == null || targetLat == null || targetLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLng,
    );
  }

  /// Verifica se o técnico está dentro do raio permitido (padrão: 100 metros)
  bool isWithinRadius(double? targetLat, double? targetLng, {double radiusMeters = 100.0}) {
    final dist = distanceTo(targetLat, targetLng);
    if (dist == null) return false;
    return dist <= radiusMeters;
  }

  /// Interrompe o rastreamento (ex: logout)
  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
