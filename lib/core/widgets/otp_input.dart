import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import 'ui_kit.dart';

/// Six masked boxes split 3 - 3, backed by one hidden text field so paste and
/// SMS autofill work.
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool hasError;
  final String errorText;
  final TextEditingController? controller;

  const OtpInput({super.key, required this.onChanged, this.hasError = false, this.errorText = 'Incorrect code entered', this.controller});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final code = _controller.text;

    Widget box(int i) {
      final filled = i < code.length;
      final active = _focus.hasFocus && i == code.length.clamp(0, 5);
      final borderColor = widget.hasError ? AppColors.error : (active ? context.p.brand : p.border);
      return Expanded(
        child: AspectRatio(
          aspectRatio: 0.92,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: active || widget.hasError ? 1.5 : 1),
            ),
            child: Text(filled ? '*' : (active ? '' : '•'),
                style: tx(context, filled ? 20 : 12, weight: FontWeight.w800, color: filled ? p.text : p.textMuted)),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        // Invisible field that actually receives input.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
              },
              showCursor: false,
              enableInteractiveSelection: false,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            box(0), box(1), box(2),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('-', style: tx(context, 16, color: p.textMuted))),
            box(3), box(4), box(5),
          ]),
        ),
      ]),
      if (widget.hasError) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Text(widget.errorText, style: tx(context, 11.5, color: AppColors.error)),
        ]),
      ],
    ]);
  }
}
