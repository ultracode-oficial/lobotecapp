import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço responsável por gerenciar e solicitar permissões do sistema
/// (Localização e Câmera) logo na inicialização/entrada do app.
class PermissionService {
  static bool _requestedThisSession = false;

  /// Solicita as permissões essenciais do aplicativo:
  /// - Localização (para validação de check-in e rotas)
  /// - Câmera (para fotos de checklist dos equipamentos)
  static Future<void> requestAppPermissions() async {
    if (_requestedThisSession) return;
    _requestedThisSession = true;

    try {
      developer.log(
        'Solicitando permissões iniciais (Localização e Câmera)...',
        name: 'PermissionService',
      );

      final statuses = await [
        Permission.location,
        Permission.camera,
      ].request();

      developer.log(
        'Resultado das permissões: Localização=${statuses[Permission.location]}, Câmera=${statuses[Permission.camera]}',
        name: 'PermissionService',
      );
    } on MissingPluginException catch (e) {
      developer.log(
        'permission_handler não registrado na sessão atual (requer rebuild nativo). Usando fallback Geolocator.',
        name: 'PermissionService',
        error: e,
      );
      try {
        await Geolocator.requestPermission();
      } catch (_) {}
    } catch (e) {
      developer.log('Erro ao solicitar permissões: $e', name: 'PermissionService');
      try {
        await Geolocator.requestPermission();
      } catch (_) {}
    }
  }

  /// Verifica se a permissão de localização foi concedida
  static Future<bool> isLocationGranted() async {
    try {
      return await Permission.location.isGranted;
    } catch (_) {
      try {
        final perm = await Geolocator.checkPermission();
        return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
      } catch (_) {
        return false;
      }
    }
  }

  /// Verifica se a permissão de câmera foi concedida
  static Future<bool> isCameraGranted() async {
    try {
      return await Permission.camera.isGranted;
    } catch (_) {
      return false;
    }
  }
}
