import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/ui_kit.dart';

class CustomDomainScreen extends StatefulWidget {
  const CustomDomainScreen({super.key});

  @override
  State<CustomDomainScreen> createState() => _CustomDomainScreenState();
}

class _CustomDomainScreenState extends State<CustomDomainScreen> {
  final store = BizStore.instance;
  late final _domain = TextEditingController(text: store.storefront.customDomain ?? '');
  bool _busy = false;

  static final _pattern = RegExp(r'^(?!-)([a-z0-9-]{1,63}\.)+[a-z]{2,}$');

  @override
  void initState() {
    super.initState();
    // Live: refresh the DNS / SSL status of a saved domain.
    if (store.storefront.customDomain != null) _check(quiet: true);
  }

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  String get _value => _domain.text.trim().toLowerCase().replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');
  bool get _valid => _pattern.hasMatch(_value);

  Future<void> _check({bool quiet = false}) async {
    setState(() => _busy = true);
    await runLiveAction(context, LiveSession.instance.checkDomain, done: quiet ? null : 'Domain status updated');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save(String? domain) async {
    setState(() => _busy = true);
    final ok = await runLiveAction(
      context,
      () => LiveSession.instance.saveStorefront(customDomain: domain ?? ''),
      done: domain == null ? 'Custom domain removed' : 'Domain saved — add the CNAME record to finish',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  static (String, String) _statusText(String? s) => switch (s) {
    'live' => ('Live', 'Your store opens on this domain with a secure (https) connection.'),
    'ssl_pending' => ('Securing', 'DNS is set. We’re issuing the security certificate; this can take up to an hour.'),
    'propagating' => ('Waiting for DNS', 'Your domain points somewhere else. Check the CNAME record below.'),
    'action_required' => ('Action needed', 'Add the CNAME record below at your domain provider.'),
    _ => ('Not set up', 'Save a domain to get started.'),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: store, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final sf = store.storefront;
    final target = sf.expectedCname;
    final locked = !sf.hasCustomDomainPlan;

    return InnerScaffold(
      title: 'Custom Domain',
      subtitle: 'Use your own web address for the store, like shop.yourbusiness.com. Your link keeps working too.',
      bottom: locked ? null : CustomButton(text: 'Save Domain', isLoading: _busy, onPressed: _valid && !_busy ? () => _save(_value) : null),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked) ...[
            const InfoBanner('Custom domains come with plans that include them. See More → Wallet & Billing.', icon: Icons.lock_outline),
            const SizedBox(height: 14),
          ],
          CustomTextField(
            label: 'Domain',
            hint: 'shop.yourbusiness.com',
            controller: _domain,
            readOnly: locked,
            keyboardType: TextInputType.url,
            errorText: _domain.text.isNotEmpty && !_valid ? 'Enter a domain like shop.yourbusiness.com' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          if (sf.customDomain != null) ...[
            BpCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statusText(sf.domainStatus).$1, style: tx(context, 13.5, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(_statusText(sf.domainStatus).$2, style: tx(context, 11.5, color: context.p.textSecondary, height: 1.35)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _busy ? null : () => _check(), child: const Text('Check')),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          InfoBanner(
            target == null
                ? 'After saving, add the CNAME record shown here at your domain provider. It can take a few hours to start working.'
                : 'After saving, add a CNAME record pointing to $target at your domain provider. It can take a few hours to start working.',
          ),
          if (sf.customDomain != null && !locked) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: _busy ? null : () => _save(null), child: const Text('Remove custom domain')),
          ],
        ],
      ),
    );
  }
}
