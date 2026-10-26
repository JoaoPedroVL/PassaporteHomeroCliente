import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import 'profile_avatar.dart';

/// Capa do passaporte: identidade do viajante e resumo das conquistas.
class PassportCover extends StatelessWidget {
  const PassportCover({
    super.key,
    required this.perfil,
    required this.totalViagens,
    required this.totalInsignias,
  });

  final UserProfile perfil;
  final int totalViagens;
  final int totalInsignias;

  @override
  Widget build(BuildContext context) {
    final desde = perfil.createdAt?.year;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepGreen, AppColors.forest],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: Icon(
              Icons.public,
              size: 190,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  width: 18,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldLight),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.goldLight,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PASSAPORTE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                        color: AppColors.goldLight.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Passaporte Brasil',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.goldLight,
                        fontSize: 28,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'República Federativa do Viajante',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.62),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    ProfileAvatar(
                      iniciais: perfil.iniciais,
                      size: 52,
                      backgroundColor: AppColors.goldLight,
                      foregroundColor: AppColors.deepGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perfil.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'CrimsonText',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            perfil.groupName ?? 'Viajante independente',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Estatistica(
                      valor: totalViagens.toString(),
                      rotulo: totalViagens == 1 ? 'viagem' : 'viagens',
                    ),
                    const SizedBox(width: 28),
                    _Estatistica(
                      valor: totalInsignias.toString(),
                      rotulo: totalInsignias == 1 ? 'insígnia' : 'insígnias',
                    ),
                    const Spacer(),
                    if (desde != null)
                      Text(
                        'Desde $desde',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 0.4,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Estatistica extends StatelessWidget {
  const _Estatistica({required this.valor, required this.rotulo});

  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: const TextStyle(
            fontFamily: 'CrimsonText',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.goldLight,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}
