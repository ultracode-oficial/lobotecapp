import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Current active page index in HomeScreen navigation
  int homeCurrentIndex = 0;

  // OS List Data
  final List<ServiceOrder> serviceOrders = [
    ServiceOrder(
      id: '#003650-RJ',
      clientName: 'Hospital São Lucas',
      address: 'Av. Brasil, 1500',
      distance: '1.2km',
      tasksSummary: 'Higienização | Carga de Fluido Refrigerante | Ajuste de Dreno',
      nextStepDate: '15/05/2026',
      stepsCount: 2,
      steps: [
        StepModel(
          id: 'Etapa 1',
          date: '15/05/2026',
          equipments: [
            EquipmentModel(
              id: 'Equipamento 1',
              isRegistered: true,
              tag: 'TAG-HOSP-01',
              location: 'Ala Oeste - Térreo',
              brand: 'Daikin',
              type: 'Hi-Wall',
              btu: '18.000',
              evaporator: 'EVAP-1234',
              condenser: 'COND-5678',
              observations: 'Filtro levemente sujo, necessita limpeza.',
              tasks: {
                'Higienização': false,
                'Carga de Fluido Refrigerante': false,
                'Ajuste de Dreno': false,
              },
            ),
            EquipmentModel(
              id: 'Equipamento 2',
              isRegistered: false,
              tasks: {
                'Higienização': false,
                'Carga de Fluido Refrigerante': false,
                'Limpeza dos Filtros': false,
              },
            ),
          ],
        ),
        StepModel(
          id: 'Etapa 2',
          date: '16/05/2026',
          equipments: [],
          isFinalized: false,
        )
      ],
    ),
    ServiceOrder(
      id: '#052826-43',
      clientName: 'Escola Pingo de Gente',
      address: 'Rua das Flores, 450',
      distance: '2.5km',
      tasksSummary: 'Limpeza de Filtro | Reparo Elétrico',
      nextStepDate: '16/05/2026',
      stepsCount: 1,
      steps: [
        StepModel(id: 'Etapa 1', date: '16/05/2026', equipments: []),
      ],
    ),
    ServiceOrder(
      id: '#052826-14',
      clientName: 'Supermercado Todo Dia',
      address: 'Rua Principal, 1200',
      distance: '1.2km',
      tasksSummary: 'Manutenção Preventiva Semestral',
      nextStepDate: '17/05/2026',
      stepsCount: 3,
      steps: [
        StepModel(id: 'Etapa 1', date: '17/05/2026', equipments: []),
      ],
    ),
  ];

  // Helper getters for active OS and steps
  ServiceOrder get activeOS => serviceOrders[0];
  StepModel get activeStep => activeOS.steps[0];

  // Notify listeners when changing tabs or indexes
  void setHomeIndex(int index) {
    homeCurrentIndex = index;
    notifyListeners();
  }

  // Update check-in state
  void performCheckIn(String stepId) {
    activeStep.isCheckedIn = true;
    notifyListeners();
  }

  // Register equipment details
  void registerEquipment(String eqId, {
    required String tag,
    required String location,
    required String brand,
    required String type,
    required String btu,
    required String evaporator,
    required String condenser,
    required String observations,
  }) {
    final eq = activeStep.equipments.firstWhere((e) => e.id == eqId);
    eq.tag = tag;
    eq.location = location;
    eq.brand = brand;
    eq.type = type;
    eq.btu = btu;
    eq.evaporator = evaporator;
    eq.condenser = condenser;
    eq.observations = observations;
    eq.isRegistered = true;
    notifyListeners();
  }

  // Save checklist data
  void saveChecklist(String eqId, ChecklistData data) {
    final eq = activeStep.equipments.firstWhere((e) => e.id == eqId);
    eq.checklistData = data;
    eq.isChecklistFilled = true;
    notifyListeners();
  }

  // Toggle equipment specific task status
  void toggleTask(String eqId, String taskKey) {
    final eq = activeStep.equipments.firstWhere((e) => e.id == eqId);
    if (eq.tasks.containsKey(taskKey)) {
      eq.tasks[taskKey] = !(eq.tasks[taskKey] ?? false);
      notifyListeners();
    }
  }

  // Finalize an individual equipment
  void finalizeEquipment(String eqId) {
    final eq = activeStep.equipments.firstWhere((e) => e.id == eqId);
    eq.isFinalized = true;
    notifyListeners();
  }

  // Set signature
  void collectSignature() {
    activeStep.isSignatureCollected = true;
    notifyListeners();
  }

  // Finalize the active step
  void finalizeActiveStep() {
    activeStep.isFinalized = true;
    notifyListeners();
  }

  // Finalize the active OS
  void finalizeActiveOS() {
    activeOS.isFinalized = true;
    notifyListeners();
  }
}

class ServiceOrder {
  final String id;
  final String clientName;
  final String address;
  final String distance;
  final String tasksSummary;
  final String nextStepDate;
  final int stepsCount;
  final List<StepModel> steps;
  bool isFinalized;

  ServiceOrder({
    required this.id,
    required this.clientName,
    required this.address,
    required this.distance,
    required this.tasksSummary,
    required this.nextStepDate,
    required this.stepsCount,
    required this.steps,
    this.isFinalized = false,
  });

  int get completedStepsCount => steps.where((s) => s.isFinalized).length;
}

class StepModel {
  final String id;
  final String date;
  final List<EquipmentModel> equipments;
  bool isCheckedIn;
  bool isSignatureCollected;
  bool isFinalized;

  StepModel({
    required this.id,
    required this.date,
    required this.equipments,
    this.isCheckedIn = false,
    this.isSignatureCollected = false,
    this.isFinalized = false,
  });

  int get completedEquipmentsCount => equipments.where((e) => e.isFinalized).length;
  bool get allEquipmentsCompleted => equipments.isNotEmpty && equipments.every((e) => e.isFinalized);
}

class EquipmentModel {
  final String id;
  bool isRegistered;
  String tag;
  String location;
  String brand;
  String type;
  String btu;
  String evaporator;
  String condenser;
  String observations;

  // Task lists
  final Map<String, bool> tasks;

  bool isChecklistFilled;
  ChecklistData? checklistData;
  bool isFinalized;

  EquipmentModel({
    required this.id,
    this.isRegistered = false,
    this.tag = '',
    this.location = '',
    this.brand = '',
    this.type = '',
    this.btu = '',
    this.evaporator = '',
    this.condenser = '',
    this.observations = '',
    required this.tasks,
    this.isChecklistFilled = false,
    this.checklistData,
    this.isFinalized = false,
  });

  int get completedTasksCount => tasks.values.where((v) => v).length;
  bool get allTasksCompleted => tasks.isNotEmpty && tasks.values.every((v) => v);
}

class ChecklistData {
  final String? photoBeforePath;
  final String? photoAfterPath;
  final String temperature;
  final String status; // Normal / Necessita de Corretiva
  final String observations;

  // Corrective information if status is "Necessita de Corretiva"
  final String? problem;
  final String? solution;
  final String? materialNeeded;
  final String? estimatedTime;

  ChecklistData({
    this.photoBeforePath,
    this.photoAfterPath,
    required this.temperature,
    required this.status,
    required this.observations,
    this.problem,
    this.solution,
    this.materialNeeded,
    this.estimatedTime,
  });
}
