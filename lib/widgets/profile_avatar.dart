import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar circular com iniciais, usado no passaporte e no perfil.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.iniciais,
    this.size = 48,
    this.backgroundColor = AppColors.gold,
    this.foregroundColor = AppColors.deepGreen,
    this.borderColor = AppColors.goldLight,
  });

  final String iniciais;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        iniciais,
        style: TextStyle(
          fontFamily: 'CrimsonText',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
          color: foregroundColor,
        ),
      ),
    );
  }
}
