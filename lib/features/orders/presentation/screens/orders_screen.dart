import 'package:flutter/material.dart';
import '../../../../core/data/biz_store.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'order_details_screen.dart';

/// More → Orders: storefront orders, filterable by All / Pending / Paid.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final store = BizStore.instance;
  String _q = '';
  OrderStatus? _filter;

  static const _filters = [(null, 'All'), (OrderStatus.pending, 'Pending'), (OrderStatus.processing, 'Paid'), (OrderStatus.cancelled, 'Cancelled')];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = context.p;
        final q = _q.toLowerCase();
        final list = store.orders
            .where((o) => (_filter == null || o.status == _filter) && (q.isEmpty || o.customerName.toLowerCase().contains(q) || o.number.toLowerCase().contains(q)))
            .toList();

        return InnerScaffold(
          title: 'Orders',
          scroll: false,
          bodyPadding: EdgeInsets.zero,
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            SearchField(hint: 'Search customer name', onChanged: (v) => setState(() => _q = v)),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final (s, label) in _filters)
                  Padding(padding: const EdgeInsets.only(right: 8), child: SelectChip(label: label, selected: _filter == s, onTap: () => setState(() => _filter = s))),
              ]),
            ),
            const SizedBox(height: 14),
            if (store.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: EmptyState(icon: Icons.shopping_bag_outlined, title: 'No Orders Yet', message: 'When customers place orders from your storefront, they will show up here.'),
              )
            else if (list.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.search_off, title: 'No matching orders'))
            else
              for (final o in list)
                RecordTile(
                  leading: LeadingIcon(Icons.shopping_bag_outlined, color: o.isNew ? null : p.textSecondary),
                  title: o.customerName,
                  subtitle: '${o.number} · ${Fmt.relativeDay(o.placedAt)}${o.isNew ? ' · New' : ''}',
                  amount: o.total,
                  status: BizStatus.order(o.status),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: o))),
                ),
          ]),
        );
      },
    );
  }
}
