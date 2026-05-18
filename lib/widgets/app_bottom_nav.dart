import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme_controller.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _item({
    required int index,
    required IconData icon,
    required String label,
    required Color primary,
    required Color secondary,
  }) {
    final selected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 3,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: selected ? secondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Icon(
                icon,
                size: 24,
                color: selected ? primary : AppColors.navInactive,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : AppColors.navInactive,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
    final theme = context.watch<AppThemeController>();

    return Material(
      color: Colors.white,
      elevation: 14,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _item(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Início',
                primary: theme.primary,
                secondary: theme.secondary,
              ),
              _item(
                index: 1,
                icon: Icons.calendar_month_rounded,
                label: 'Agenda',
                primary: theme.primary,
                secondary: theme.secondary,
              ),
              _item(
                index: 2,
                icon: Icons.people_alt_rounded,
                label: 'Clientes',
                primary: theme.primary,
                secondary: theme.secondary,
              ),
              _item(
                index: 3,
                icon: Icons.assignment_rounded,
                label: 'Ordens',
                primary: theme.primary,
                secondary: theme.secondary,
              ),
              _item(
                index: 4,
                icon: Icons.more_horiz_rounded,
                label: 'Mais',
                primary: theme.primary,
                secondary: theme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
