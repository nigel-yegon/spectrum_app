import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_state.dart';
import '../models/unit.dart';
import 'properties_screen.dart';
import 'tenants_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';
import 'property_detail_screen.dart';

// ─── Theme Colors (Based on the reference design) ─────────────────────────
const Color _bgCream = Color(0xFFF9F9F6);
const Color _primaryGreen = Color(0xFF1E3A2F);
const Color _accentGreen = Color(0xFF2E7D5E);
const Color _textDark = Color(0xFF1A1A1A);
const Color _textGrey = Color(0xFF7A7A7A);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: IndexedStack(
        index: _index,
        children: const [
          _HomeTab(),
          PropertiesScreen(),
          TenantsScreen(),
          PaymentsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_outlined), // Better property icon
            selectedIcon: Icon(Icons.domain_rounded),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Tenants',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined), // Better payment icon
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = NumberFormat.currency(symbol: 'KSh ', decimalDigits: 0);
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryGreen,
          onRefresh: state.loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Top Bar ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Spectrum Manager',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _CircleButton(
                            icon: Icons.search,
                            onTap: () {}, // Future: Global Search
                          ),
                          const SizedBox(width: 8),
                          _CircleButton(
                            icon: Icons.settings_outlined,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Main Balance Card (Dark Green) ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryGreen.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Expected Rent',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.visibility_off_outlined,
                                    color: Colors.white70, size: 16),
                              ],
                            ),
                            const Icon(Icons.bar_chart_rounded,
                                color: Colors.white, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currency.format(state.totalMonthlyExpectedRent),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_upward,
                                      color: Color(0xFFA9D9B6), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    currency.format(state.totalCollectedThisMonth),
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA9D9B6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Collected this month',
                              style: GoogleFonts.inter(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Quick Actions ────────────────────────────────────
                  // ─── Quick Actions ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        icon: Icons.add_rounded, // matches "+" in image
                        label: 'Add Unit',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PropertiesScreen())),
                      ),
                      _QuickAction(
                        icon: Icons.send_rounded, // matches "Send" paper plane
                        label: 'Send STK',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                      ),
                      _QuickAction(
                        icon: Icons.person_add_alt_1_rounded, // matches "Convert"
                        label: 'New Tenant',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const TenantsScreen())),
                      ),
                      _QuickAction(
                        icon: Icons.more_horiz_rounded, // matches "More" dots
                        label: 'More',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ─── Contextual Info Banner ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EA), // Light green tint
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco, color: _accentGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to Spectrum',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage properties, track M-Pesa rent, and automate tenant invoicing all in one place.',
                                style: GoogleFonts.inter(
                                  color: _primaryGreen.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── Properties Overview ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Properties',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PropertiesScreen())),
                        child: Text(
                          'See all',
                          style: GoogleFonts.inter(
                            color: _accentGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (state.properties.isEmpty)
                    _EmptyHint(
                      message: 'No properties yet. Add your first property to begin.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PropertiesScreen(),
                          ),
                        );
                      },
                    )
                  else
                    ...state.properties.map((p) {
                      final units = state.unitsForProperty(p.id);
                      final occupied =
                          units.where((u) => u.status == UnitStatus.occupied).length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _bgCream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.apartment, color: _primaryGreen),
                          ),
                          title: Text(
                            p.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                p.address,
                                style: GoogleFonts.inter(
                                  color: _textGrey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$occupied of ${units.length} units occupied',
                                style: GoogleFonts.inter(
                                  color: _accentGreen,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: _textGrey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PropertyDetailScreen(
                                  property: p,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, color: _textDark, size: 20),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: _primaryGreen, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textDark,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _EmptyHint({
    required this.message,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 40,
            color: _accentGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _textGrey),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onTap,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}