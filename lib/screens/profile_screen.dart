import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/colors.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../widgets/status_badge.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 8),
            Text('Sair do App'),
          ],
        ),
        content: const Text(
          'Deseja realmente encerrar sua sessão? Você precisará fazer login novamente para acessar suas ordens de serviço.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado para a área de transferência'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        UserEntity? user;
        if (state is AuthAuthenticated) {
          user = state.user;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Meu Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Atualizar dados',
                onPressed: () {
                  context.read<AuthBloc>().add(AuthCheckSessionRequested());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Atualizando informações do perfil...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(AuthCheckSessionRequested());
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Header com Card de Perfil
                _buildHeaderCard(context, user),
                const SizedBox(height: 16),

                // Card de Informações Pessoais
                _buildSectionTitle('Informações de Contato'),
                const SizedBox(height: 8),
                _buildInfoCard(context, user),
                const SizedBox(height: 16),

                // Card de Segurança
                _buildSectionTitle('Segurança & Acesso'),
                const SizedBox(height: 8),
                _buildSecurityCard(context, user),
                const SizedBox(height: 16),

                // Permissões e Cargo
                _buildSectionTitle('Permissões do Cargo'),
                const SizedBox(height: 8),
                _buildPermissionsCard(user),
                const SizedBox(height: 16),

                // Informações Técnicas do App
                _buildSectionTitle('Diretrizes de Campo & Sistema'),
                const SizedBox(height: 8),
                _buildSystemInfoCard(),
                const SizedBox(height: 24),

                // Botão de Logout
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text(
                      'Sair da Conta',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, UserEntity? user) {
    final displayName = user?.name.isNotEmpty == true ? user!.name : 'Técnico de Campo';
    final roleName = user?.primaryRole.isNotEmpty == true ? user!.primaryRole : 'TÉCNICO';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  backgroundImage: user?.photo != null && user!.photo!.isNotEmpty
                      ? NetworkImage(user.photo!)
                      : null,
                  child: user?.photo == null || user!.photo!.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grupo LoboRJ • Climatização',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                        label: roleName,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const StatusBadge(
                        label: 'EM CAMPO',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UserEntity? user) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.email_outlined,
            title: 'E-mail',
            value: user?.email.isNotEmpty == true ? user!.email : 'Não informado',
            onCopy: user?.email.isNotEmpty == true
                ? () => _copyToClipboard(context, user!.email, 'E-mail')
                : null,
          ),
          const Divider(height: 1, indent: 52),
          _buildInfoTile(
            icon: Icons.phone_android_outlined,
            title: 'Telefone',
            value: user?.phone?.isNotEmpty == true ? user!.phone! : 'Não informado',
            onCopy: user?.phone?.isNotEmpty == true
                ? () => _copyToClipboard(context, user!.phone!, 'Telefone')
                : null,
          ),
          const Divider(height: 1, indent: 52),
          _buildInfoTile(
            icon: Icons.badge_outlined,
            title: 'CPF',
            value: user?.cpf?.isNotEmpty == true ? user!.cpf! : 'Não cadastrado',
            onCopy: user?.cpf?.isNotEmpty == true
                ? () => _copyToClipboard(context, user!.cpf!, 'CPF')
                : null,
          ),
          if (user?.bio?.isNotEmpty == true) ...[
            const Divider(height: 1, indent: 52),
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'Biografia / Especialidade',
              value: user!.bio!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onCopy,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: onCopy != null
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
              tooltip: 'Copiar',
              onPressed: onCopy,
            )
          : null,
    );
  }

  Widget _buildSecurityCard(BuildContext context, UserEntity? user) {
    final mfaActive = user?.mfaEnabled == true;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (mfaActive ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mfaActive ? Icons.verified_user : Icons.gpp_maybe,
                color: mfaActive ? AppColors.success : AppColors.warning,
                size: 20,
              ),
            ),
            title: const Text(
              'Autenticação em Dois Fatores (MFA)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              mfaActive ? 'Ativo e protegido via Token' : 'Não ativado para sua conta',
              style: TextStyle(
                fontSize: 12,
                color: mfaActive ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            trailing: StatusBadge(
              label: mfaActive ? 'ATIVO' : 'OPCIONAL',
              color: mfaActive ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const Divider(height: 1, indent: 52),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 20),
            ),
            title: const Text(
              'Alterar Senha de Acesso',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Atualize sua senha de login com segurança',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(user: user),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(UserEntity? user) {
    final permissions = user?.permissions ?? [];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Escopo de Execução Técnica',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (permissions.isEmpty)
              const Text(
                'EXECUTAR_SERVICOS • ACESSO_MOBILE • LOGIN',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: permissions.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          p,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSystemRow(
              icon: Icons.location_on_outlined,
              title: 'Geofencing de Check-in',
              subtitle: 'Raio de tolerância: 100 metros até o cliente',
            ),
            const Divider(height: 20),
            _buildSystemRow(
              icon: Icons.cloud_done_outlined,
              title: 'Operação Offline Habilitada',
              subtitle: 'Checklists e formulários são salvos localmente',
            ),
            const Divider(height: 20),
            _buildSystemRow(
              icon: Icons.info_outline,
              title: 'Versão do Aplicativo',
              subtitle: 'LoboTec Técnico v1.0.0 (Grupo LoboRJ)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
