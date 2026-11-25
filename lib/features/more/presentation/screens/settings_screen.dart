import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/biometrics.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../workspace/workspace_screens.dart';
import '../../../store/presentation/widgets/store_widgets.dart';
import 'appearance_screen.dart';
import 'two_factor_settings_screen.dart';

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
              onChanged: (on) async {
                if (!LiveSession.enabled) return store.setBiometrics(on);
                // Live: needs a real fingerprint / Face ID check, and is saved on this device.
                final now = await Biometrics.setEnabled(on);
                store.setBiometrics(now);
                if (on && !now && context.mounted) showToast(context, 'Fingerprint / Face ID isn’t set up on this device, or it wasn’t confirmed.');
              },
            ),
          ),
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.password,
            title: 'Change password',
            subtitle: 'Enter your current password to set a new one',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          if (LiveSession.enabled)
            ActionTile(
              icon: Icons.phonelink_lock_outlined,
              title: 'Two-step verification',
              subtitle: 'Ask for an authenticator code when you log in',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorSettingsScreen())),
            ),
          // No backend endpoint for revoking other sessions yet.
          if (!LiveSession.enabled)
            ActionTile(
              icon: Icons.devices_other,
              title: 'Log out of other devices',
              subtitle: 'Keeps you signed in on this phone',
              onTap: () async {
                final ok = await showConfirmSheet(context, title: 'Log out other devices?', message: 'Anyone signed in elsewhere will need your password again.', confirmLabel: 'Log Them Out', cancelLabel: 'Cancel');
                if (ok && context.mounted) showToast(context, 'Other devices logged out');
              },
            ),
          const SizedBox(height: 12),
          const SectionLabel('Danger zone'),
          ActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete my account',
            subtitle: 'Removes your login and signs you out',
            danger: true,
            onTap: () => _deleteAccount(context),
          ),
        ]),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await showConfirmSheet(
      context,
      title: 'Delete your account?',
      message: 'You will be signed out and won’t be able to log in again with this email. This can’t be undone from the app.',
      confirmLabel: 'Delete Account',
      cancelLabel: 'Keep Account',
    );
    if (!ok || !context.mounted) return;
    try {
      if (LiveSession.enabled) await LiveSession.instance.deleteAccount();
    } on ApiException catch (e) {
      if (context.mounted) showToast(context, e.message);
      return;
    }
    if (!context.mounted) return;
    BizStore.instance.logOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }
}
