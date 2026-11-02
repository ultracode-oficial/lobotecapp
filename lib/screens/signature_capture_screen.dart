import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import '../core/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignatureCaptureResult {
  final String imagePath;
  final String nome;
  final String cpf;

  const SignatureCaptureResult({
    required this.imagePath,
    required this.nome,
    required this.cpf,
  });
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limited[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String formatCpf(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return cpf;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
}

class SignatureCaptureScreen extends StatefulWidget {
  final String? clienteNome;
  final String? numeroOs;

  const SignatureCaptureScreen({
    super.key,
    this.clienteNome,
    this.numeroOs,
  });

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  late final SignatureController _signatureController;
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  bool _isSaving = false;
  bool _dadosConfirmados = false;
  String? _nomeError;
  String? _cpfError;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3.5,
      penColor: Colors.black87,
      exportBackgroundColor: Colors.white,
    );
    _restorePortrait();
  }

  Future<void> _enterLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    _restorePortrait();
    super.dispose();
  }

  String get _nomeDigitado => _nomeController.text.trim();
  String get _cpfDigitos => _cpfController.text.replaceAll(RegExp(r'\D'), '');

  bool _validarDados() {
    setState(() {
      _nomeError = _nomeDigitado.isEmpty ? 'Informe o nome de quem vai assinar.' : null;
      _cpfError = _cpfDigitos.length != 11 ? 'Informe um CPF com 11 dígitos.' : null;
    });
    return _nomeError == null && _cpfError == null;
  }

  Future<void> _continuarParaAssinar() async {
    if (!_validarDados()) return;
    setState(() => _dadosConfirmados = true);
    await _enterLandscape();
  }

  Future<void> _voltarParaDados() async {
    _signatureController.clear();
    await _restorePortrait();
    if (mounted) setState(() => _dadosConfirmados = false);
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, solicite a assinatura do cliente antes de salvar.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imageBytes = await _signatureController.toPngBytes();
      if (imageBytes == null) {
        setState(() => _isSaving = false);
        return;
      }

      final tempDir = Directory.systemTemp;
      final fileName =
          'assinatura_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      await _restorePortrait();

      if (mounted) {
        Navigator.pop(
          context,
          SignatureCaptureResult(
            imagePath: file.path,
            nome: _nomeDigitado,
            cpf: _cpfDigitos,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar assinatura: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildForm() {
    final displayOs =
        widget.numeroOs?.isNotEmpty == true ? ' • ${widget.numeroOs}' : '';
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Assinatura do Cliente$displayOs'),
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _restorePortrait();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quem vai assinar?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.clienteNome?.isNotEmpty == true
                    ? 'Informe o nome e o CPF da pessoa que vai assinar pelo cliente ${widget.clienteNome}.'
                    : 'Informe o nome e o CPF da pessoa que vai assinar.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Nome de quem vai assinar *',
                hint: 'Nome completo',
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              if (_nomeError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _nomeError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                label: 'CPF de quem vai assinar *',
                hint: '000.000.000-00',
                controller: _cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [_CpfInputFormatter()],
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              if (_cpfError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _cpfError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 28),
              CustomButton(
                text: 'CONTINUAR PARA ASSINAR',
                isPrimary: true,
                onPressed: () => _continuarParaAssinar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    final displayName = _nomeDigitado;
    final displayOs =
        widget.numeroOs?.isNotEmpty == true ? ' • ${widget.numeroOs}' : '';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _restorePortrait();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar aos dados',
                      icon: const Icon(Icons.arrow_back,
                          size: 22, color: AppColors.textSecondary),
                      onPressed: _voltarParaDados,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Assinatura do Cliente$displayOs',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$displayName • CPF ${formatCpf(_cpfDigitos)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'Limpar',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      onPressed: () => _signatureController.clear(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: Text(
                        _isSaving ? 'Salvando...' : 'Confirmar',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isSaving ? null : _saveSignature,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 32,
                            right: 32,
                            bottom: 36,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'X',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 1.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Assinatura do Responsável ($displayName)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Assine no espaço com o dedo ou caneta touch',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _dadosConfirmados ? _buildCanvas() : _buildForm();
  }
}
