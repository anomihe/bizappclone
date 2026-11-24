import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/otp_input.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../widgets/auth_scaffold.dart';

/// One screen for "Verify your phone", "Verify your device" and
/// "Verify it's you". [onVerified] runs after a successful check.
///
/// Demo rule until the API exists: any 6 digits pass except `000000`,
/// which shows the "Incorrect code entered" state.
class OtpVerificationScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final void Function(BuildContext context) onVerified;

  const OtpVerificationScreen({super.key, required this.title, required this.subtitle, required this.onVerified});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _resendSeconds = 60;
  final _controller = TextEditingController();
  String _code = '';
  bool _error = false;
  bool _loading = false;
  int _seconds = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_code == '000000') {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }
    setState(() => _loading = false);
    widget.onVerified(context);
  }

  void _resend() {
    _controller.clear();
    setState(() {
      _code = '';
      _error = false;
    });
    _startTimer();
    showToast(context, 'A new code has been sent');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');

    return AuthScaffold(
      showClose: false,
      title: widget.title,
      subtitle: widget.subtitle,
      footer: CustomButton(
        text: 'Verify',
        isLoading: _loading,
        onPressed: _code.length == 6 ? _verify : null,
      ),
      children: [
        OtpInput(
          controller: _controller,
          hasError: _error,
          onChanged: (v) => setState(() {
            _code = v;
            _error = false;
          }),
        ),
        const SizedBox(height: 22),
        Center(
          child: _error || _seconds == 0
              ? OutlinedButton(
                  onPressed: _resend,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Resend Code', style: tx(context, 12.5, weight: FontWeight.w700, color: context.p.brand)),
                )
              : Text.rich(TextSpan(children: [
                  TextSpan(text: 'You can ask for a new code in ', style: tx(context, 12.5, color: p.textSecondary)),
                  TextSpan(text: '$mm:$ss', style: tx(context, 12.5, weight: FontWeight.w700, color: AppColors.error)),
                ])),
        ),
      ],
    );
  }
}
