import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/bizpaddi_logo.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const BizpaddiLogo(size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acme Technologies',
                  style: GoogleFonts.figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Trial: 14 days left',
                  style: GoogleFonts.figtree(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Toggle Button
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 22,
              color: isDark ? AppColors.accent : AppColors.primary,
            ),
            onPressed: () {
              ThemeController.instance.toggleTheme();
            },
          ),
          // Notifications Bell with Badge
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  size: 24,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _InvoicesTab(),
          _OrdersTab(),
          _TasksTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navbar : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.border : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
          selectedLabelStyle: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.figtree(fontSize: 11, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Invoices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// 1. Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Revenue Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.primary, AppColors.primaryDark]
                    : [AppColors.primary, const Color(0xFF104A3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL REVENUE (THIS MONTH)',
                      style: GoogleFonts.figtree(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: AppColors.accent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '+18.4%',
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₦14,850,000.00',
                  style: GoogleFonts.figtree(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operating Wallet',
                          style: GoogleFonts.figtree(fontSize: 11, color: Colors.white70),
                        ),
                        Text(
                          '₦45,200.00',
                          style: GoogleFonts.figtree(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Text(
                        '+ Top Up',
                        style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Quick Action Bar
          Text(
            'Quick Actions',
            style: GoogleFonts.figtree(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickAction(context, '+ New Invoice', Icons.add_circle_outline),
                _buildQuickAction(context, '+ Add Product', Icons.inventory_2_outlined),
                _buildQuickAction(context, '+ New Lead', Icons.person_add_alt_1_outlined),
                _buildQuickAction(context, 'Assign Task', Icons.assignment_turned_in_outlined),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pending AI Approvals Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.border : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Workforce Pending Actions',
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '2 blog posts & 1 draft quote awaiting approval',
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Review',
                    style: GoogleFonts.figtree(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Invoices Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Invoices',
                style: GoogleFonts.figtree(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInvoiceCard(
            context,
            clientName: 'Heritage Holdings Ltd',
            invoiceNo: '#INV-2026-084',
            amount: '₦850,000.00',
            status: 'PAID',
            bankInfo: 'SafeHaven MFB - 9920194821',
          ),
          const SizedBox(height: 10),
          _buildInvoiceCard(
            context,
            clientName: 'Apex Media Group',
            invoiceNo: '#INV-2026-085',
            amount: '₦420,000.00',
            status: 'DUE',
            bankInfo: 'SafeHaven MFB - 9920194822',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surface : Colors.white,
          side: BorderSide(
            color: isDark ? AppColors.border : AppColors.lightBorder,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        icon: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(
          text,
          style: GoogleFonts.figtree(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context, {
    required String clientName,
    required String invoiceNo,
    required String amount,
    required String status,
    required String bankInfo,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPaid = status == 'PAID';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                clientName,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.success.withOpacity(0.18)
                      : AppColors.warning.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.figtree(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                invoiceNo,
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.figtree(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: bankInfo));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Virtual bank account copied to clipboard!'),
                  duration: Duration(milliseconds: 900),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceLight : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bankInfo,
                      style: GoogleFonts.figtree(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const Icon(Icons.copy_outlined, size: 13, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Invoices Tab Placeholder
class _InvoicesTab extends StatelessWidget {
  const _InvoicesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Invoices & Quotations Hub',
        style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// 3. Orders Tab Placeholder
class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Storefront Orders Desk',
        style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// 4. Tasks Tab Placeholder
class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Projects & Kanban Tasks',
        style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// 5. Settings Tab
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        ListTile(
          title: Text(
            'Appearance & Theme Mode',
            style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isDark ? 'Dark Mode (Active)' : 'Light Mode (Active)',
            style: GoogleFonts.figtree(fontSize: 12),
          ),
          trailing: Switch(
            value: isDark,
            activeColor: AppColors.primary,
            onChanged: (val) {
              ThemeController.instance.toggleTheme();
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security),
          title: Text('Two-Factor Authentication (2FA)', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: Text('KYC & Business Verification', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text('Custom Domain Mapping', style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () {},
        ),
      ],
    );
  }
}
