import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
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

  static final _pattern = RegExp(r'^(?!-)([a-z0-9-]{1,63}\.)+[a-z]{2,}$');

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  String get _value => _domain.text.trim().toLowerCase().replaceFirst(RegExp(r'^https?://'), '');
  bool get _valid => _pattern.hasMatch(_value);

  @override
  Widget build(BuildContext context) {
    return InnerScaffold(
      title: 'Custom Domain',
      subtitle: 'Use your own web address for the store, like shop.yourbusiness.com. Your link keeps working too.',
      bottom: CustomButton(
        text: 'Save Domain',
        onPressed: _valid
            ? () {
                store.storefront.customDomain = _value;
                store.updateStorefront();
                showToast(context, 'Domain saved — add the CNAME record to finish');
                Navigator.pop(context);
              }
            : null,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CustomTextField(
          label: 'Domain',
          hint: 'shop.yourbusiness.com',
          controller: _domain,
          keyboardType: TextInputType.url,
          errorText: _domain.text.isNotEmpty && !_valid ? 'Enter a domain like shop.yourbusiness.com' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        const InfoBanner(
          'After saving, add a CNAME record pointing to stores.bizpaddi.example at your domain provider. '
          'It can take a few hours to start working. Address shown is a sample.',
        ),
        if (store.storefront.customDomain != null) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              store.storefront.customDomain = null;
              store.updateStorefront();
              Navigator.pop(context);
            },
            child: const Text('Remove custom domain'),
          ),
        ],
      ]),
    );
  }
}
