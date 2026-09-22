import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  final UserEntity user;

  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final current = _currentController.text;
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A nova senha e a confirmação não coincidem.')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthChangePasswordRequested(
            currentPassword: current,
            newPassword: newPass,
            newPasswordConfirmation: confirm,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.lock_reset_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Troca de Senha Obrigatória',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Olá, ${widget.user.name.split(' ').first}! Para continuar, você precisa definir uma nova senha.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    label: 'Senha Atual',
                    hint: 'Insira sua senha atual',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    controller: _currentController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Nova Senha',
                    hint: 'Mínimo 8 caracteres',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_open_rounded),
                    controller: _newController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Confirmar Nova Senha',
                    hint: 'Repita a nova senha',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    controller: _confirmController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 32),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Definir Nova Senha',
                          onPressed: _submit,
                        ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                    child: const Text(
                      'Sair',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
