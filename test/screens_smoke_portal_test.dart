import 'package:bizpaddi/core/api/live_session.dart';
import 'package:bizpaddi/core/theme/app_theme.dart';
import 'package:bizpaddi/features/portal/customer_app.dart';
import 'package:bizpaddi/features/portal/portal_kit.dart';
import 'package:bizpaddi/features/portal/portal_projects.dart';
import 'package:bizpaddi/features/portal/staff_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/sample_workspace.dart';

/// Staff and customer screens on sample data, at every supported size, in
/// light and dark mode (split from screens_smoke_test.dart to keep each test
/// process within memory).
void main() {
  final staff = <String, Widget Function()>{
    'staff app': () => const StaffShell(),
    'staff task': () => const StaffTaskScreen(taskId: 31, title: 'Cut fabric'),
    'staff start session': () => const StartSessionScreen(),
    'staff end session': () => const EndSessionScreen(sessionId: 7),
    'staff daily report': () => const NewReportScreen(),
    'staff salary account': () => const BankAccountScreen(),
    'staff performance': () => const PerformanceScreen(),
    'pm project': () => const PmProjectScreen(projectId: 3, name: 'Obi wedding outfits'),
    'pm task form': () => const PmTaskForm(projectId: 3),
    'staff support thread': () => const SupportChatThreadScreen(chatId: 1, subject: 'Question about my invoice'),
  };
  final customer = <String, Widget Function()>{
    'customer app': () => const CustomerShell(),
    'customer invoice': () => const CustomerInvoiceScreen(id: 21),
    'customer new ticket': () => const NewTicketScreen(),
    'customer services': () => const ServicesScreen(),
    'portal project': () => const PortalProjectScreen(projectId: 3, name: 'Obi wedding outfits'),
    'portal profile': () => const PortalProfileScreen(),
    'support messages': () => const SupportChatsScreen(),
  };

  const sizes = <String, (Size, double)>{
    'phone': (Size(390, 844), 1.0),
    'small phone': (Size(320, 640), 1.0),
    'phone landscape': (Size(844, 390), 1.0),
    'tablet': (Size(820, 1180), 1.0),
    'desktop': (Size(1440, 900), 1.0),
    'phone large text': (Size(390, 844), 1.3),
  };

  for (final (role, screens) in [(AccountRole.staff, staff), (AccountRole.customer, customer)]) {
    for (final dark in [false, true]) {
      for (final size in sizes.entries) {
        for (final entry in screens.entries) {
          testWidgets('${entry.key} renders (${dark ? 'dark' : 'light'}, ${size.key})', (tester) async {
            LiveSession.instance.useTestAccount(role);
            addTearDown(() => LiveSession.instance.useTestAccount(AccountRole.owner));
            final (logical, textScale) = size.value;
            tester.view.physicalSize = logical * 2;
            tester.view.devicePixelRatio = 2;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: entry.value(),
            ));
            await tester.pump(const Duration(milliseconds: 800));
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 2));
          });
        }
      }
    }
  }
}
