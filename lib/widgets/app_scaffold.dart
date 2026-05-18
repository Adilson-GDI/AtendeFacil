import 'package:flutter/material.dart';
import 'app_header.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final int currentIndex;
  final bool showBack;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.currentIndex,
    this.showBack = false,
    this.floatingActionButton,
  });

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/agenda', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/clientes',
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/ordens', (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/configuracoes',
          (route) => false,
        );
        break;
    }
  }

  void _back(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          AppHeader(
            title: title,
            subtitle: subtitle,
            showBack: showBack,
            menuActive: currentIndex == 4,
            onBack: () => _back(context),
            onMenu: () {
              if (currentIndex != 4) {
                Navigator.pushNamed(context, '/configuracoes');
              }
            },
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }
}
