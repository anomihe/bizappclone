import 'package:flutter/material.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';
import '../../../../core/widgets/ui_kit.dart';

const appVersion = '1.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    void open(LegalDoc d) => Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => LegalScreen(doc: d)));
    return InnerScaffold(
      title: 'About Us',
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(18)),
            child: const BizpaddiLogo(size: 52),
          ),
        ),
        const SizedBox(height: 10),
        Text('Bizpaddi', textAlign: TextAlign.center, style: tx(context, 16, weight: FontWeight.w800)),
        Text('Version $appVersion', textAlign: TextAlign.center, style: tx(context, 12, color: p.textMuted)),
        const SizedBox(height: 22),
        ActionTile(icon: Icons.shield_outlined, title: 'Privacy Policy', onTap: () => open(LegalDoc.privacy)),
        ActionTile(icon: Icons.description_outlined, title: 'Terms of Use', onTap: () => open(LegalDoc.terms)),
        ActionTile(icon: Icons.code, title: 'Open Source Licenses', onTap: () => showLicensePage(context: context, applicationName: 'Bizpaddi', applicationVersion: appVersion)),
      ]),
    );
  }
}

enum LegalDoc { privacy, terms }

/// Draft legal copy from the Figma frames. Replace with counsel-approved text
/// before release.
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  static const _privacy = [
    ('Information we handle', 'Your privacy matters. This policy describes how Bizpaddi handles personal information when you use the app. We may handle account details, information you enter, support messages and technical usage data. The final policy must confirm the exact categories collected.'),
    ('How information is used', 'To provide app features, maintain your account, respond to requests and help keep the service secure. Any optional analytics or marketing use must be disclosed separately.'),
    ('Sharing and retention', 'The final policy must identify service providers, legal disclosures, storage locations and how long each type of information is kept.'),
    ('Your choices and rights', 'Depending on applicable law, you may request access, correction or deletion of your data. You can manage device permissions in your device settings.'),
    ('Contact and policy updates', 'Before publication, add the responsible business, privacy contact, request process and effective date. Explain how material changes will be communicated.'),
  ];

  static const _terms = [
    ('Using Bizpaddi', 'These terms explain the conditions for using Bizpaddi. Read them alongside the Privacy Policy. Use the app lawfully and provide accurate information. Do not misuse the service, attempt unauthorised access or interfere with other users.'),
    ('Your account', 'Keep your sign-in details secure. You are responsible for activity under your account. Report anything you think is unauthorised through the app’s support channel.'),
    ('Your content and our app', 'You retain ownership of content you submit. You must have permission to share it. Bizpaddi and third-party materials remain subject to their owners’ rights.'),
    ('Availability and responsibility', 'Features may change or be unavailable from time to time. Nothing in these terms excludes consumer rights or liabilities that cannot lawfully be excluded.'),
    ('Before these terms take effect', 'Confirm the legal entity, eligibility, fees, cancellation rules, account closure process, liability limits, governing law, dispute process and support contact. Add an effective date and explain how changes will be notified.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final sections = doc == LegalDoc.privacy ? _privacy : _terms;
    return InnerScaffold(
      title: doc == LegalDoc.privacy ? 'Privacy Policy' : 'Terms Of Use',
      leadingIcon: Icons.close,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Draft for review · Not yet effective', style: tx(context, 11, color: p.textMuted)),
        const SizedBox(height: 12),
        for (final (title, body) in sections) ...[
          Text(title, style: tx(context, 13.5, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(body, style: tx(context, 12.5, color: p.textSecondary, height: 1.5)),
          const SizedBox(height: 14),
        ],
      ]),
    );
  }
}
