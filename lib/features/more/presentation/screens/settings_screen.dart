import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../auth/presentation/screens/forgot_password_screen.dart';
import '../../../store/presentation/widgets/store_widgets.dart';
import 'appearance_screen.dart';

/// More → Settings: appearance and notifications.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([store, ThemeController.instance]),
      builder: (context, _) => InnerScaffold(
        title: 'Settings',
        subtitle: 'Appearance and notifications',
        body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionLabel('Appearance'),
          ActionTile(
            icon: Icons.contrast,
            title: 'Theme',
            subtitle: themeModeLabel(ThemeController.instance.themeMode),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
          const SizedBox(height: 12),
          const SectionLabel('Push notifications'),
          BpCard(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: Column(children: [
              for (final e in store.notificationPrefs.entries)
                ToggleRow(title: e.key, value: e.value, onChanged: (v) => store.setNotificationPref(e.key, v)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// More → Security. Not in the Figma yet; built from existing pieces.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => InnerScaffold(
        title: 'Security',
        subtitle: 'Password, biometrics, sessions',
        body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BpCard(
            padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
            child: ToggleRow(
              title: 'Log in with fingerprint / Face ID',
              subtitle: 'You can always use your password.',
              value: store.account.biometricsEnabled,
              onChanged: store.setBiometrics,
            ),
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.password,
            title: 'Change password',
            subtitle: 'We send a code to confirm it’s you',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
          ),
          ActionTile(
            icon: Icons.devices_other,
            title: 'Log out of other devices',
            subtitle: 'Keeps you signed in on this phone',
            onTap: () async {
              final ok = await showConfirmSheet(context, title: 'Log out other devices?', message: 'Anyone signed in elsewhere will need your password again.', confirmLabel: 'Log Them Out', cancelLabel: 'Cancel');
              if (ok && context.mounted) showToast(context, 'Other devices logged out');
            },
          ),
        ]),
      ),
    );
  }
}
