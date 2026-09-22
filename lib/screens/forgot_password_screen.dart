import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../core/di/injection_container.dart';
import '../features/auth/domain/usecases/forgot_password_usecases.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

// ── Cubit ─────────────────────────────────────────────────────────────────────

enum ForgotPasswordStep { email, code, newPassword, done }

class _ForgotPasswordState {
  final ForgotPasswordStep step;
  final bool isLoading;
  final String? error;
  final String email;

  const _ForgotPasswordState({
    this.step = ForgotPasswordStep.email,
    this.isLoading = false,
    this.error,
    this.email = '',
  });

  _ForgotPasswordState copyWith({
    ForgotPasswordStep? step,
    bool? isLoading,
    String? error,
    String? email,
  }) =>
      _ForgotPasswordState(
        step: step ?? this.step,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        email: email ?? this.email,
      );
}

class _ForgotPasswordCubit extends Cubit<_ForgotPasswordState> {
  final SendResetCodeUseCase _sendCode;
  final VerifyResetCodeUseCase _verifyCode;
  final ResetPasswordUseCase _resetPassword;

  _ForgotPasswordCubit()
      : _sendCode = getIt<SendResetCodeUseCase>(),
        _verifyCode = getIt<VerifyResetCodeUseCase>(),
        _resetPassword = getIt<ResetPasswordUseCase>(),
        super(const _ForgotPasswordState());

  Future<void> sendCode(String email) async {
    emit(state.copyWith(isLoading: true));
    final result = await _sendCode(email);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.code,
        email: email,
      )),
    );
  }

  Future<void> verifyCode(String code) async {
    emit(state.copyWith(isLoading: true));
    final result = await _verifyCode(email: state.email, code: code);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.newPassword,
      )),
    );
  }

  Future<void> resetPassword(String password, String confirmation, String code) async {
    emit(state.copyWith(isLoading: true));
    final result = await _resetPassword(
      email: state.email,
      code: code,
      password: password,
      passwordConfirmation: confirmation,
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (_) => emit(state.copyWith(
        isLoading: false,
        step: ForgotPasswordStep.done,
      )),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _ForgotPasswordCubit(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Recuperar Senha',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: BlocConsumer<_ForgotPasswordCubit, _ForgotPasswordState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context, _ForgotPasswordState state) {
    switch (state.step) {
      case ForgotPasswordStep.email:
        return _EmailStep(
          controller: _emailController,
          isLoading: state.isLoading,
          onNext: () => context.read<_ForgotPasswordCubit>().sendCode(_emailController.text.trim()),
        );
      case ForgotPasswordStep.code:
        return _CodeStep(
          controller: _codeController,
          email: state.email,
          isLoading: state.isLoading,
          onNext: () => context.read<_ForgotPasswordCubit>().verifyCode(_codeController.text.trim()),
        );
      case ForgotPasswordStep.newPassword:
        return _NewPasswordStep(
          passwordController: _passwordController,
          confirmController: _confirmController,
          isLoading: state.isLoading,
          onNext: () => context.read<_ForgotPasswordCubit>().resetPassword(
                _passwordController.text,
                _confirmController.text,
                _codeController.text.trim(),
              ),
        );
      case ForgotPasswordStep.done:
        return _DoneStep(onBack: () => Navigator.of(context).pop());
    }
  }
}

// ── Step Widgets ──────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onNext;

  const _EmailStep({required this.controller, required this.isLoading, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.email_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 20),
        const Text('Informe seu e-mail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Enviaremos um código de 6 dígitos para redefinição.', style: TextStyle(color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        CustomTextField(label: 'E-mail', hint: 'seu@email.com', prefixIcon: const Icon(Icons.mail_outline), controller: controller, enabled: !isLoading),
        const SizedBox(height: 24),
        isLoading ? const Center(child: CircularProgressIndicator()) : CustomButton(text: 'Enviar Código', onPressed: onNext),
      ],
    );
  }
}

class _CodeStep extends StatelessWidget {
  final TextEditingController controller;
  final String email;
  final bool isLoading;
  final VoidCallback onNext;

  const _CodeStep({required this.controller, required this.email, required this.isLoading, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 20),
        const Text('Verifique seu e-mail', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Código enviado para $email', style: const TextStyle(color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !isLoading,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 10, color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(fontSize: 28, letterSpacing: 10, color: AppColors.textSecondary.withAlpha(80)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        const SizedBox(height: 24),
        isLoading ? const Center(child: CircularProgressIndicator()) : CustomButton(text: 'Verificar Código', onPressed: onNext),
      ],
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final VoidCallback onNext;

  const _NewPasswordStep({required this.passwordController, required this.confirmController, required this.isLoading, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.primary),
        const SizedBox(height: 20),
        const Text('Nova Senha', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 36),
        CustomTextField(label: 'Nova Senha', hint: 'Mínimo 8 caracteres', isPassword: true, prefixIcon: const Icon(Icons.lock_open_rounded), controller: passwordController, enabled: !isLoading),
        const SizedBox(height: 20),
        CustomTextField(label: 'Confirmar Senha', hint: 'Repita a nova senha', isPassword: true, prefixIcon: const Icon(Icons.check_circle_outline), controller: confirmController, enabled: !isLoading),
        const SizedBox(height: 24),
        isLoading ? const Center(child: CircularProgressIndicator()) : CustomButton(text: 'Redefinir Senha', onPressed: onNext),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  final VoidCallback onBack;

  const _DoneStep({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Senha Redefinida!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Sua senha foi alterada com sucesso. Faça login com sua nova senha.', style: TextStyle(color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        CustomButton(text: 'Voltar ao Login', onPressed: onBack),
      ],
    );
  }
}
