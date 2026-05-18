import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme_controller.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final bool menuActive;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBack = false,
    this.onBack,
    this.onMenu,
    this.menuActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppThemeController>();

    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      color: theme.primary,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              )
            else
              const SizedBox(width: 48),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: menuActive
                      ? theme.secondary.withOpacity(0.18)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: menuActive ? theme.secondary : Colors.white24,
                    width: menuActive ? 1.4 : 1,
                  ),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: menuActive ? theme.secondary : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
