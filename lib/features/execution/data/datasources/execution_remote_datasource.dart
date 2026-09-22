import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/checklist_model.dart';
import '../models/dashboard_model.dart';
import '../models/equipment_model.dart';
import '../models/service_order_model.dart';
import '../models/step_model.dart';
import '../models/task_model.dart';

abstract class ExecutionRemoteDataSource {
  Future<DashboardModel> getDashboard();

  Future<List<ServiceOrderModel>> getServiceOrders({
    String? status,
    String? dataInicio,
    String? dataFim,
    int? perPage,
  });

  Future<ServiceOrderModel> getServiceOrderDetail(int id);

  Future<Map<String, dynamic>> finalizeServiceOrder(int id);

  Future<List<StepModel>> getAgenda({
    required String dataInicio,
    required String dataFim,
    String? status,
  });

  Future<Map<String, dynamic>> getAgendaOcupacao({
    required String dataInicio,
    required String dataFim,
  });

  Future<StepModel> getStepDetail(int etapaId);

  Future<StepModel> performCheckIn(
    int etapaId, {
    required double lat,
    required double lng,
  });

  Future<String> uploadSignature(int etapaId, String imagePath);

  Future<Map<String, dynamic>> finalizeStep(
    int etapaId, {
    bool confirmRemocaoNaoIniciados = false,
  });

  Future<List<EquipmentModel>> getEquipments(int etapaId);

  Future<EquipmentModel> getEquipmentDetail(
    int etapaId,
    int equipamentoServicoId,
  );

  Future<void> startEquipment(int etapaId, int equipamentoServicoId);

  Future<EquipmentModel> registerEquipment(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  );

  Future<ChecklistModel> saveChecklist(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  );

  Future<Map<String, dynamic>> uploadChecklistPhoto(
    int etapaId,
    int equipamentoServicoId, {
    required String tipo,
    required String imagePath,
  });

  Future<Map<String, dynamic>> finalizeEquipment(
    int etapaId,
    int equipamentoServicoId, {
    bool confirmPendencias = false,
  });

  Future<TaskModel> toggleTask(int tarefaId, {String? status});
}

class ExecutionRemoteDataSourceImpl implements ExecutionRemoteDataSource {
  final ApiClient _client;

  ExecutionRemoteDataSourceImpl({required this._client});

  @override
  Future<DashboardModel> getDashboard() async {
    final response = await _client.get(ApiConstants.executarDashboard);
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ServiceOrderModel>> getServiceOrders({
    String? status,
    String? dataInicio,
    String? dataFim,
    int? perPage,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (dataInicio != null) params['data_inicio'] = dataInicio;
    if (dataFim != null) params['data_fim'] = dataFim;
    if (perPage != null) params['per_page'] = perPage;

    final response = await _client.get(
      ApiConstants.executarServicos,
      queryParameters: params.isNotEmpty ? params : null,
    );

    final data = response.data;
    List items = [];
    if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => ServiceOrderModel.fromJson(e))
        .toList();
  }

  @override
  Future<ServiceOrderModel> getServiceOrderDetail(int id) async {
    final response = await _client.get(ApiConstants.executarServicoDetail(id));
    return ServiceOrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> finalizeServiceOrder(int id) async {
    final response = await _client.post(ApiConstants.executarServicoFinalizar(id));
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<StepModel>> getAgenda({
    required String dataInicio,
    required String dataFim,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'data_inicio': dataInicio,
      'data_fim': dataFim,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _client.get(
      ApiConstants.executarAgenda,
      queryParameters: params,
    );

    final data = response.data;
    List items = [];
    if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => StepModel.fromJson(e))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getAgendaOcupacao({
    required String dataInicio,
    required String dataFim,
  }) async {
    final response = await _client.get(
      ApiConstants.executarAgendaOcupacao,
      queryParameters: {
        'data_inicio': dataInicio,
        'data_fim': dataFim,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<StepModel> getStepDetail(int etapaId) async {
    final response = await _client.get(ApiConstants.executarEtapaDetail(etapaId));
    return StepModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<StepModel> performCheckIn(
    int etapaId, {
    required double lat,
    required double lng,
  }) async {
    final response = await _client.post(
      ApiConstants.executarEtapaCheckIn(etapaId),
      data: {'lat': lat, 'lng': lng},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['etapa'] != null) {
      return StepModel.fromJson(data['etapa'] as Map<String, dynamic>);
    }
    return StepModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<String> uploadSignature(int etapaId, String imagePath) async {
    final formData = FormData.fromMap({
      'assinatura': await MultipartFile.fromFile(imagePath),
    });

    final response = await _client.post(
      ApiConstants.executarEtapaAssinatura(etapaId),
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return (data['assinatura_url'] ?? data['url'] ?? '') as String;
  }

  @override
  Future<Map<String, dynamic>> finalizeStep(
    int etapaId, {
    bool confirmRemocaoNaoIniciados = false,
  }) async {
    final response = await _client.post(
      ApiConstants.executarEtapaFinalizar(etapaId),
      data: confirmRemocaoNaoIniciados
          ? {'confirm_remocao_nao_iniciados': true}
          : null,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<EquipmentModel>> getEquipments(int etapaId) async {
    final response =
        await _client.get(ApiConstants.executarEtapaEquipamentos(etapaId));
    final data = response.data;
    List items = [];
    if (data is Map && data['data'] is List) {
      items = data['data'] as List;
    } else if (data is List) {
      items = data;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => EquipmentModel.fromJson(e))
        .toList();
  }

  @override
  Future<EquipmentModel> getEquipmentDetail(
    int etapaId,
    int equipamentoServicoId,
  ) async {
    final response = await _client.get(
      ApiConstants.executarEquipamentoDetail(etapaId, equipamentoServicoId),
    );
    return EquipmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> startEquipment(int etapaId, int equipamentoServicoId) async {
    await _client.post(
      ApiConstants.executarEquipamentoIniciar(etapaId, equipamentoServicoId),
    );
  }

  @override
  Future<EquipmentModel> registerEquipment(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      ApiConstants.executarEquipamentoRegistro(etapaId, equipamentoServicoId),
      data: data,
    );
    return EquipmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ChecklistModel> saveChecklist(
    int etapaId,
    int equipamentoServicoId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.put(
      ApiConstants.executarEquipamentoChecklist(etapaId, equipamentoServicoId),
      data: data,
    );
    return ChecklistModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> uploadChecklistPhoto(
    int etapaId,
    int equipamentoServicoId, {
    required String tipo,
    required String imagePath,
  }) async {
    final formData = FormData.fromMap({
      'tipo': tipo,
      'foto': await MultipartFile.fromFile(imagePath),
    });

    final response = await _client.post(
      ApiConstants.executarEquipamentoChecklistFoto(etapaId, equipamentoServicoId),
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> finalizeEquipment(
    int etapaId,
    int equipamentoServicoId, {
    bool confirmPendencias = false,
  }) async {
    final response = await _client.post(
      ApiConstants.executarEquipamentoFinalizar(etapaId, equipamentoServicoId),
      data: confirmPendencias ? {'confirm_pendencias': true} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<TaskModel> toggleTask(int tarefaId, {String? status}) async {
    final response = await _client.patch(
      ApiConstants.executarTarefaToggle(tarefaId),
      data: status != null ? {'status': status} : null,
    );
    return TaskModel.fromJson(response.data as Map<String, dynamic>);
  }
}
