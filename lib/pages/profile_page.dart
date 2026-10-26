import 'package:flutter/material.dart';

import '../core/cpf.dart';
import '../core/formatters.dart';
import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/responsive_body.dart';
import '../widgets/section_title.dart';
import '../widgets/status_chip.dart';

/// Perfil: dados da conta, informações do app e saída.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.perfil});

  final UserProfile perfil;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _saindo = false;

  Future<void> _sair() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisará entrar novamente para acessar o seu passaporte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() => _saindo = true);
    try {
      await supabase.auth.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair agora. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = widget.perfil;
    final cpfTexto = perfil.cpf?.trim() ?? '';
    final temCpf = cpfTexto.isNotEmpty;
    final identificador = temCpf
        ? 'CPF ${formatarCpf(cpfTexto)}'
        : (perfil.email.isEmpty ? 'E-mail não informado' : perfil.email);

    return Scaffold(
      appBar: const BrandAppBar(subtitulo: 'Perfil'),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProfileAvatar(iniciais: perfil.iniciais, size: 84),
                    const SizedBox(height: 14),
                    Text(
                      perfil.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      identificador,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        StatusChip(
                          label: perfil.admin ? 'Administrador' : 'Viajante',
                          color: AppColors.deepGreen,
                          icon: perfil.admin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                        ),
                        StatusChip(
                          label: perfil.groupName ?? 'Sem grupo',
                          color: AppColors.gold,
                          icon: Icons.groups_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(titulo: 'Sua conta'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    _InfoLinha(
                      icon: temCpf
                          ? Icons.badge_outlined
                          : Icons.mail_outline,
                      label: temCpf ? 'CPF' : 'E-mail',
                      value: temCpf
                          ? formatarCpf(cpfTexto)
                          : (perfil.email.isEmpty ? '—' : perfil.email),
                      compacto: true,
                    ),
                    const Divider(height: 1),
                    _InfoLinha(
                      icon: Icons.groups_outlined,
                      label: 'Grupo',
                      value: perfil.groupName ?? 'Sem grupo',
                    ),
                    const Divider(height: 1),
                    _InfoLinha(
                      icon: Icons.schedule_outlined,
                      label: 'Último acesso',
                      value: perfil.lastSeenAt == null
                          ? 'Agora'
                          : dataHoraBR(perfil.lastSeenAt),
                    ),
                    const Divider(height: 1),
                    _InfoLinha(
                      icon: Icons.calendar_today_outlined,
                      label: 'Viajante desde',
                      value: perfil.createdAt == null
                          ? '—'
                          : dataBR(perfil.createdAt),
                    ),
                    const Divider(height: 1),
                    _InfoLinha(
                      icon: Icons.verified_user_outlined,
                      label: 'Status',
                      value: perfil.ativo ? 'Ativo' : 'Inativo',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle(titulo: 'Sobre'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold),
                        color: AppColors.gold.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.gold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passaporte Brasil',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Seu passaporte de viagens, memórias e insígnias.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Versão 0.1.0',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saindo ? null : _sair,
              icon: _saindo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.danger,
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 18),
              label: Text(_saindo ? 'Saindo...' : 'Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  const _InfoLinha({
    required this.icon,
    required this.label,
    required this.value,
    this.compacto = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: compacto
                      ? theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: AppColors.ink,
                        )
                      : theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
