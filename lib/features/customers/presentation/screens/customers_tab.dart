import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'customer_details_screen.dart';
import 'customer_form_screen.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final store = BizStore.instance;
  String _q = '';

  void _add() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final q = _q.toLowerCase().replaceAll(' ', '');
        final list = store.customers
            .where((c) => c.name.toLowerCase().replaceAll(' ', '').contains(q) || c.phone.replaceAll(' ', '').contains(q))
            .toList();

        return Column(children: [
          TabHeader(
            title: 'Customers',
            trailing: CircleIconButton(icon: Icons.person_add_alt_1, background: AppColors.primary, color: Colors.white, tooltip: 'New customer', onTap: _add),
          ),
          Expanded(
            child: TabPanel(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
                SearchField(hint: 'Search customer or number', onChanged: (v) => setState(() => _q = v)),
                const SizedBox(height: 12),
                if (store.customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'No customers yet',
                      message: 'Add your first customer to start invoicing.',
                      action: CustomButton(text: 'Add Customer', width: 200, height: 42, onPressed: _add),
                    ),
                  )
                else if (list.isEmpty)
                  const Padding(padding: EdgeInsets.only(top: 50), child: EmptyState(icon: Icons.person_search_outlined, title: 'No matching customers'))
                else
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: BpCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: c))),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Row(children: [
                          InitialsAvatar(c.name, size: 36),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.name, style: tx(context, 13.5, weight: FontWeight.w700)),
                              Text(c.phone, style: tx(context, 11.5, color: p.textMuted)),
                            ]),
                          ),
                          if (store.owedBy(c) > 0)
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Owes', style: tx(context, 10.5, color: p.textMuted)),
                              Text(Fmt.money(store.owedBy(c)), style: tx(context, 13, weight: FontWeight.w800, color: AppColors.warning)),
                            ]),
                        ]),
                      ),
                    ),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
