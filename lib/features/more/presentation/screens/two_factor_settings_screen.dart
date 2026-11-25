import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Security → Two-step verification (authenticator app), live mode only.
class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() => _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  final _code = TextEditingController();
  Map<String, dynamic>? _state;
  String? _loadError;
  String? _codeError;
  bool _busy = false;
  List<String>? _recovery;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final s = await LiveSession.instance.business.twoFactor();
      if (mounted) setState(() => _state = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      final codes = await LiveSession.instance.business.confirmTwoFactor(_code.text);
      if (mounted) setState(() => _recovery = codes);
    } on ApiException catch (e) {
      if (mounted) setState(() => _codeError = e.errorFor('code') ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _turnOff() async {
    final password = TextEditingController();
    String? error;
    var busy = false;
    final off = await showBpSheet<bool>(
      context,
      showHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Turn off two-step verification?', style: tx(sheet, 16, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Anyone with your password will be able to log in. Enter your password to confirm.', style: tx(sheet, 12.5, color: sheet.p.textSecondary, height: 1.4)),
          const SizedBox(height: 14),
          CustomTextField(label: 'Password', hint: 'Enter Password', controller: password, isPassword: true, errorText: error, onChanged: (_) => setSheet(() => error = null)),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Turn Off',
            variant: ButtonVariant.outline,
            isLoading: busy,
            onPressed: () async {
              setSheet(() => busy = true);
              try {
                await LiveSession.instance.business.disableTwoFactor(password.text);
                if (sheet.mounted) Navigator.pop(sheet, true);
              } on ApiException catch (e) {
                setSheet(() {
                  busy = false;
                  error = e.errorFor('password') ?? e.message;
                });
              }
            },
          ),
        ]),
      ),
    );
    if (off == true && mounted) {
      showToast(context, 'Two-step verification is off');
      setState(() {
        _state = null;
        _recovery = null;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return InnerScaffold(
      title: 'Two-step verification',
      subtitle: 'A code from an authenticator app at every login',
      body: _loadError != null
          ? EmptyState(icon: Icons.cloud_off, title: 'Couldn’t load this', message: _loadError, action: CustomButton(text: 'Try Again', onPressed: _load))
          : s == null
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : _recovery != null
                  ? _recoveryCodes(context, _recovery!)
                  : s['enabled'] == true
                      ? _enabled(context)
                      : _setup(context, s),
    );
  }

  Widget _enabled(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          child: Row(children: [
            Icon(Icons.verified_user, color: context.p.brand),
            const SizedBox(width: 10),
            Expanded(child: Text('Two-step verification is on. You’ll be asked for a code from your authenticator app when you log in.', style: tx(context, 12.5, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 14),
        ActionTile(icon: Icons.no_encryption_gmailerrorred_outlined, title: 'Turn off two-step verification', danger: true, onTap: _turnOff),
      ]);

  Widget _setup(BuildContext context, Map<String, dynamic> s) {
    final p = context.p;
    final secret = '${s['secret'] ?? ''}';
    final url = '${s['otpauth_url'] ?? ''}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('1. Scan this code with an authenticator app (Google Authenticator, Microsoft Authenticator, 1Password…).',
          style: tx(context, 12.5, color: p.textSecondary, height: 1.4)),
      const SizedBox(height: 12),
      if (url.isNotEmpty)
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: url, size: 180, backgroundColor: Colors.white),
          ),
        ),
      const SizedBox(height: 12),
      Text('Can’t scan? Enter this key instead:', style: tx(context, 12, color: p.textSecondary)),
      const SizedBox(height: 6),
      BpCard(
        onTap: () {
          Clipboard.setData(ClipboardData(text: secret));
          showToast(context, 'Key copied');
        },
        child: Row(children: [
          Expanded(child: SelectableText(secret, style: tx(context, 14, weight: FontWeight.w700))),
          Icon(Icons.copy, size: 18, color: p.textMuted),
        ]),
      ),
      const SizedBox(height: 18),
      Text('2. Enter the 6-digit code the app shows.', style: tx(context, 12.5, color: p.textSecondary)),
      const SizedBox(height: 10),
      OtpInput(controller: _code, hasError: _codeError != null, errorText: _codeError ?? '', onChanged: (_) => setState(() => _codeError = null)),
      const SizedBox(height: 18),
      CustomButton(text: 'Turn On', isLoading: _busy, onPressed: _code.text.length == 6 && !_busy ? _confirm : null),
    ]);
  }

  Widget _recoveryCodes(BuildContext context, List<String> codes) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BpCard(
          child: Row(children: [
            Icon(Icons.verified_user, color: context.p.brand),
            const SizedBox(width: 10),
            Expanded(child: Text('Two-step verification is on.', style: tx(context, 13.5, weight: FontWeight.w800))),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Save these recovery codes somewhere safe. If you lose your phone, each one lets you log in once. They won’t be shown again.',
            style: tx(context, 12.5, color: context.p.textSecondary, height: 1.4)),
        const SizedBox(height: 12),
        BpCard(
          child: Wrap(spacing: 18, runSpacing: 8, children: [
            for (final c in codes) SelectableText(c, style: tx(context, 13.5, weight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 14),
        CustomButton(
          text: 'Copy Codes',
          variant: ButtonVariant.outline,
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: codes.join('\n')));
            showToast(context, 'Recovery codes copied');
          },
        ),
        const SizedBox(height: 10),
        CustomButton(text: 'Done', onPressed: () => Navigator.pop(context)),
      ]);
}
