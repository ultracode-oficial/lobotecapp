import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/execution/data/datasources/execution_remote_datasource.dart';
import '../features/execution/data/models/equipment_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EquipmentRegisterScreen extends StatefulWidget {
  final EquipmentModel equipment;
  final int? etapaId;

  const EquipmentRegisterScreen({
    super.key,
    required this.equipment,
    this.etapaId,
  });

  @override
  State<EquipmentRegisterScreen> createState() =>
      _EquipmentRegisterScreenState();
}

class _EquipmentRegisterScreenState extends State<EquipmentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tagController;
  late final TextEditingController _locationController;
  late final TextEditingController _btuController;
  late final TextEditingController _evaporatorController;
  late final TextEditingController _condenserController;
  late final TextEditingController _obsController;

  String? _selectedBrand;
  String? _selectedType;
  bool _isSaving = false;

  final List<String> _brands = [
    'Daikin',
    'LG',
    'Samsung',
    'Midea',
    'Gree',
    'Carrier',
    'Fujitsu',
    'Elgin',
    'Outro'
  ];
  final List<String> _types = [
    'Hi-Wall',
    'Cassete',
    'Piso Teto',
    'Duto',
    'VRF',
    'Janela'
  ];

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(text: widget.equipment.tag ?? '');
    _locationController =
        TextEditingController(text: widget.equipment.localizacao ?? '');
    _btuController = TextEditingController(text: widget.equipment.btu ?? '');
    _evaporatorController =
        TextEditingController(text: widget.equipment.evaporadora ?? '');
    _condenserController =
        TextEditingController(text: widget.equipment.condensadora ?? '');
    _obsController =
        TextEditingController(text: widget.equipment.observacoes ?? '');

    if (widget.equipment.marca != null &&
        _brands.contains(widget.equipment.marca)) {
      _selectedBrand = widget.equipment.marca;
    }
    if (widget.equipment.tipoEquipamento != null &&
        _types.contains(widget.equipment.tipoEquipamento)) {
      _selectedType = widget.equipment.tipoEquipamento;
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _locationController.dispose();
    _btuController.dispose();
    _evaporatorController.dispose();
    _condenserController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_tagController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A TAG é obrigatória.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final etapaId = widget.etapaId ?? 0;
      final data = {
        'tag': _tagController.text.trim(),
        'marca': _selectedBrand,
        'modelo': _selectedType,
        'tipo_equipamento_id': 1,
        'btu': _btuController.text.trim(),
        'evaporadora': _evaporatorController.text.trim(),
        'condensadora': _condenserController.text.trim(),
        'localizacao': _locationController.text.trim(),
        'observacoes': _obsController.text.trim(),
      };

      if (etapaId > 0) {
        final dataSource = getIt<ExecutionRemoteDataSource>();
        await dataSource.registerEquipment(
          etapaId,
          widget.equipment.id,
          data,
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipamento registrado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ficha do equipamento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro do Equipamento'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'TAG *',
                  hint: 'TAG do Equipamento (ex: TAG-001)',
                  controller: _tagController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Localização',
                  hint: 'Ex: Térreo - Recepção',
                  controller: _locationController,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Marca',
                  hint: 'Selecione a marca',
                  value: _selectedBrand,
                  items: _brands,
                  onChanged: (val) {
                    setState(() {
                      _selectedBrand = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'Tipo de Equipamento',
                  hint: 'Selecione o tipo',
                  value: _selectedType,
                  items: _types,
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'BTU',
                  hint: 'Capacidade (ex: 18000)',
                  controller: _btuController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Evaporadora',
                  hint: 'Nº de Série da Evaporadora',
                  controller: _evaporatorController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Condensadora',
                  hint: 'Nº de Série da Condensadora',
                  controller: _condenserController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Observações',
                  hint: 'Adicione observações se houver',
                  controller: _obsController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: _isSaving ? 'SALVANDO...' : 'SALVAR FICHA',
                  onPressed: _isSaving ? null : () => _saveForm(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textSecondary)),
          items: items.map((brand) {
            return DropdownMenuItem<String>(
              value: brand,
              child: Text(brand),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
