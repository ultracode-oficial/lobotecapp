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
        .whereType<Map>()
        .map((e) => ServiceOrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<ServiceOrderModel> getServiceOrderDetail(int id) async {
    final response = await _client.get(ApiConstants.executarServicoDetail(id));
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }

    var order = ServiceOrderModel.fromJson(rawData as Map<String, dynamic>);

    // Sempre buscar as etapas da OS via endpoint dedicado de etapas do técnico
    try {
      final etapasResp = await _client.get(ApiConstants.executarServicoEtapas(id));
      final etapasData = etapasResp.data;
      List rawList = [];
      if (etapasData is Map && etapasData['data'] is List) {
        rawList = etapasData['data'] as List;
      } else if (etapasData is List) {
        rawList = etapasData;
      }

      final etapas = rawList
          .whereType<Map>()
          .map((e) => StepModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (etapas.isNotEmpty) {
        final closedCount = etapas.where((e) => e.isFinalized).length;
        final allClosed = etapas.every((e) => e.isFinalized);
        order = order.copyWith(
          etapas: etapas,
          etapasClosed: closedCount > 0 ? closedCount : order.etapasClosed,
          etapasTotal: etapas.isNotEmpty ? etapas.length : order.etapasTotal,
          podeFinalizarOs: allClosed || order.podeFinalizarOs,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [Datasource] Erro ao buscar etapas adicionais da OS $id: $e');
    }

    return order;
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
        .whereType<Map>()
        .map((e) => StepModel.fromJson(Map<String, dynamic>.from(e)))
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
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }
    var step = StepModel.fromJson(rawData as Map<String, dynamic>);

    // Buscar lista de equipamentos da etapa pelo endpoint oficial
    try {
      final eqResponse = await _client.get(ApiConstants.executarEtapaEquipamentos(etapaId));
      final eqData = eqResponse.data;
      List eqList = [];
      if (eqData is Map && eqData['data'] is List) {
        eqList = eqData['data'] as List;
      } else if (eqData is List) {
        eqList = eqData;
      }
      final equipments = eqList
          .whereType<Map>()
          .map((e) => EquipmentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (equipments.isNotEmpty) {
        final done = equipments.where((e) => e.isFinalizado).length;
        step = step.copyWith(
          equipamentos: equipments,
          equipamentosTotal: equipments.length,
          equipamentosDone: done,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [Datasource] Erro ao carregar equipamentos da etapa $etapaId: $e');
    }

    return step;
  }

  @override
  Future<StepModel> performCheckIn(
    int etapaId, {
    required double lat,
    required double lng,
  }) async {
    await _client.post(
      ApiConstants.executarEtapaCheckIn(etapaId),
      data: {'lat': lat, 'lng': lng},
    );
    // Recarrega os dados completos da etapa com equipamentos após o check-in
    return await getStepDetail(etapaId);
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
        .whereType<Map>()
        .map((e) => EquipmentModel.fromJson(Map<String, dynamic>.from(e)))
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
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }
    return EquipmentModel.fromJson(rawData as Map<String, dynamic>);
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
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }
    return EquipmentModel.fromJson(rawData as Map<String, dynamic>);
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
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }
    return ChecklistModel.fromJson(rawData as Map<String, dynamic>);
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
    var rawData = response.data;
    if (rawData is Map && rawData['data'] is Map) {
      rawData = Map<String, dynamic>.from(rawData['data'] as Map);
    } else if (rawData is Map) {
      rawData = Map<String, dynamic>.from(rawData);
    } else {
      rawData = <String, dynamic>{};
    }
    return TaskModel.fromJson(rawData as Map<String, dynamic>);
  }
}
