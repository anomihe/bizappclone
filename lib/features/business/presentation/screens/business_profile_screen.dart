import 'package:flutter/material.dart';
import '../../../../core/api/live_session.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/live_actions.dart';
import '../../../../core/utils/pick_file.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../store/presentation/widgets/store_widgets.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  /// Uploads to `POST /admin/kyc`; the backend reviews it.
  Future<void> _upload(BuildContext context, String key) async {
    final file = await pickUploadFile(context, title: 'Upload $key', allowPdf: true);
    if (file == null || !context.mounted) return;
    showToast(context, 'Uploading $key…');
    await runLiveAction(context, () => LiveSession.instance.uploadKyc(key, file.bytes, file.name), done: '$key uploaded. We’ll review it shortly.');
  }

  static StatusStyle? _reviewStyle(String? s) => switch (s) {
        'pending' => const StatusStyle('In Review', Color(0xFFD48806)),
        'verified' => const StatusStyle('Approved', Color(0xFF0E8A5F)),
        'rejected' => const StatusStyle('Rejected', Color(0xFFDC2626)),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final store = BizStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final b = store.profile;
        final infoStatus = b.infoComplete ? VerificationStatus.verified : VerificationStatus.incomplete;
        final docStatus = b.documentsComplete ? VerificationStatus.verified : VerificationStatus.incomplete;

        Widget section(String title, VerificationStatus? status, List<Widget> children) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SectionLabel(title, trailing: status == null ? null : StatusPill(BizStatus.verification(status))),
                ...children,
              ]),
            );

        String orDash(String v) => v.trim().isEmpty ? '—' : v;

        return InnerScaffold(
          title: 'Business Profile',
          body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (b.verification == VerificationStatus.inReview) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withValues(alpha: 0.6))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.hourglass_top, size: 18, color: p.readable(AppColors.warning)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Account Verification in Review', style: tx(context, 13, weight: FontWeight.w800)),
                      Text('We are checking your documents. This usually takes 1–2 business days. You’ll be notified.', style: tx(context, 11.5, color: p.textSecondary)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
            ],
            BpCard(
              child: Row(children: [
                b.hasLogo ? const ProductThumb(photo: 2, size: 44) : InitialsAvatar(b.name, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.name, style: tx(context, 14, weight: FontWeight.w800)),
                    Text('Business Account', style: tx(context, 11.5, color: p.textMuted)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            section('Business Information', infoStatus, [
              BpCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(children: [
                  InfoRow(label: 'Business Name', value: orDash(b.name)),
                  InfoRow(label: 'Business Type', value: orDash(b.type)),
                  InfoRow(label: 'Registration Number', value: orDash(b.registrationNumber)),
                  InfoRow(label: 'Business Phone', value: b.phone.isEmpty ? '—' : '${b.dialCode} ${b.phone}'),
                  InfoRow(label: 'Business Email', value: orDash(b.email)),
                  InfoRow(label: 'Currency', value: b.currency),
                  InfoRow(label: 'Address', value: orDash(b.address)),
                ]),
              ),
            ]),
            section('Business Documents', docStatus, [
              for (final e in b.documents.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(e.key, style: tx(context, 12, weight: FontWeight.w600, color: p.textSecondary)),
                    const SizedBox(height: 6),
                    if (e.value == null)
                      InkWell(
                        onTap: () => _upload(context, e.key),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.border)),
                          child: Column(children: [
                            Icon(Icons.upload_file, size: 20, color: p.textSecondary),
                            Text('Upload Document', style: tx(context, 12.5, weight: FontWeight.w700)),
                            Text('PNG, JPG, PDF · 5MB max', style: tx(context, 10.5, color: p.textMuted)),
                          ]),
                        ),
                      )
                    else
                      BpCard(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                        child: Row(children: [
                          LeadingIcon(Icons.description_outlined, color: p.textSecondary, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.value!, maxLines: 1, overflow: TextOverflow.ellipsis, style: tx(context, 12.5, weight: FontWeight.w700)),
                              if (_reviewStyle(b.documentStatus[e.key]) case final s?) ...[
                                const SizedBox(height: 3),
                                StatusPill(s),
                              ] else
                                Text('Uploaded', style: tx(context, 10.5, color: p.textMuted)),
                              if (b.documentNotes[e.key] case final note?)
                                Text(note, style: tx(context, 10.5, color: p.error)),
                            ]),
                          ),
                          if (b.documentStatus[e.key] != 'verified')
                            CustomButton(text: 'Change', width: 80, height: 32, variant: ButtonVariant.outline, onPressed: () => _upload(context, e.key)),
                        ]),
                      ),
                  ]),
                ),
            ]),
            section('Bank & Settlement Details', null, [
              // There's no settlement-account API yet.
              const InfoBanner('Payouts go to the settlement account on your Bizpaddi workspace. Changing it in the app is coming soon.',
                  icon: Icons.account_balance_outlined),
            ]),
          ]),
        );
      },
    );
  }
}
