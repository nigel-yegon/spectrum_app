
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../models/unit.dart';
import '../models/payment.dart';

import 'properties_screen.dart';
import 'tenants_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';

// ─── Theme Colors ────────────────────────────────────────────────────────

const Color _bgCream = Color(0xFFF9F9F6);
const Color _primaryGreen = Color(0xFF1E3A2F);
const Color _accentGreen = Color(0xFF2E7D5E);
const Color _textDark = Color(0xFF1A1A1A);
const Color _textGrey = Color(0xFF7A7A7A);

// ─── Dashboard Screen ────────────────────────────────────────────────────

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
          InsightsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.domain_outlined),
            selectedIcon: Icon(Icons.domain_rounded),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Tenants',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final AuthService _auth = AuthService();

  bool _showRecentPayments = true;
  bool _showProperties = true;
  bool _showCurrencyAmounts = true;

  bool _profileLoading = true;
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Retrieve the saved profile name from AuthService.
  Future<void> _loadProfile() async {
    try {
      final profile = await _auth.getProfile();

      if (!mounted) return;

      setState(() {
        _profileName = (profile['fullName'] ?? '').toString().trim();
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _profileName = '';
        _profileLoading = false;
      });
    }
  }

  // Navigate to profile and reload the saved name on return.
  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (!mounted) return;

    await _loadProfile();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatCurrency(
      num amount,
      NumberFormat formatter,
      ) {
    return _showCurrencyAmounts
        ? formatter.format(amount)
        : '••••••';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final currency = NumberFormat.currency(
      symbol: 'KSh ',
      decimalDigits: 0,
    );

    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryGreen,
          onRefresh: () async {
            await Future.wait([
              state.loadAll(),
              _loadProfile(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── BRAND HEADER ─────────────────────────────────

                  Text(
                    'Spectrum Manager',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ─── GREETING AND PROFILE ─────────────────────────

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileName.isNotEmpty
                                  ? '$greeting, $_profileName'
                                  : greeting,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Here is your property overview.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      _CircleButton(
                        icon: Icons.search,
                        onTap: () {
                          // Reserved for global search.
                        },
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

                      const SizedBox(width: 8),

                      _CircleButton(
                        icon: Icons.person_outline_rounded,
                        onTap: _openProfile,
                        backgroundColor: const Color(0xFFE8F0EA),
                        iconColor: _primaryGreen,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── EXPECTED RENT CARD ───────────────────────────

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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                                IconButton(
                                  tooltip: _showCurrencyAmounts
                                      ? 'Hide amounts'
                                      : 'Show amounts',
                                  onPressed: () {
                                    setState(() {
                                      _showCurrencyAmounts =
                                      !_showCurrencyAmounts;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  icon: Icon(
                                    _showCurrencyAmounts
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _formatCurrency(
                            state.totalMonthlyExpectedRent,
                            currency,
                          ),
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    color: Color(0xFFA9D9B6),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCurrency(
                                      state.totalCollectedThisMonth,
                                      currency,
                                    ),
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

                  // ─── QUICK ACTIONS ────────────────────────────────

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Add Unit',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PropertiesScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.send_rounded,
                        label: 'Send STK',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentsScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'New Tenant',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TenantsScreen(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
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

                  const SizedBox(height: 32),

                  // ─── CONTEXTUAL BANNER ────────────────────────────

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.eco,
                          color: _accentGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to Spectrum Ventures',
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

                  // ─── YOUR PROPERTIES (COLLAPSIBLE) ─────────────────

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
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PropertiesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'See all',
                              style: GoogleFonts.inter(
                                color: _accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _showProperties
                                ? 'Hide properties'
                                : 'Show properties',
                            icon: Icon(
                              _showProperties
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: _textGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _showProperties = !_showProperties;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (_showProperties) ...[
                    const SizedBox(height: 8),

                    if (state.properties.isEmpty)
                      _EmptyHint(
                        message:
                        'No properties yet. Add your first property to begin.',
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
                      ...state.properties.map((property) {
                        final units =
                        state.unitsForProperty(property.id);

                        final occupied = units
                            .where(
                              (u) => u.status == UnitStatus.occupied,
                        )
                            .length;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _bgCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.apartment,
                                color: _primaryGreen,
                              ),
                            ),
                            title: Text(
                              property.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  property.address,
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
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: _textGrey,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailScreen(
                                    property: property,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                  ],

                  const SizedBox(height: 16),

                  // ─── RECENT PAYMENTS (COLLAPSIBLE) ────────────────

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Payments',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        tooltip: _showRecentPayments
                            ? 'Hide recent payments'
                            : 'Show recent payments',
                        icon: Icon(
                          _showRecentPayments
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _textGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _showRecentPayments =
                            !_showRecentPayments;
                          });
                        },
                      ),
                    ],
                  ),

                  if (_showRecentPayments) ...[
                    const SizedBox(height: 8),

                    if (state.payments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'No recent payments',
                            style: GoogleFonts.inter(
                              color: _textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.payments.take(5).map((payment) {
                        final tenant =
                        state.getTenant(payment.tenantId);

                        // Safe lookup: payment may reference a missing unit.
                        final matchingUnits = state.units.where(
                              (unit) => unit.id == payment.unitId,
                        );

                        final unit = matchingUnits.isEmpty
                            ? null
                            : matchingUnits.first;

                        final isPaid =
                            payment.status == PaymentStatus.confirmed;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFFE8F0EA)
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isPaid
                                      ? Icons.check_rounded
                                      : Icons.hourglass_bottom_rounded,
                                  color: isPaid
                                      ? _accentGreen
                                      : Colors.orange,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tenant?.fullName ??
                                          'Unknown Tenant',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: _textDark,
                                      ),
                                    ),
                                    Text(
                                      '${unit == null ? 'Unknown unit' : 'Unit ${unit.unitNumber}'} • ${DateFormat('MMM d').format(payment.paymentDate)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: _textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                _formatCurrency(
                                  payment.amount,
                                  currency,
                                ),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Circular Header Button ──────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? _textDark,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Quick Action ────────────────────────────────────────────────────────

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
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Icon(
              icon,
              color: _primaryGreen,
              size: 24,
            ),
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

// ─── Empty State ─────────────────────────────────────────────────────────

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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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
            style: GoogleFonts.inter(
              color: _textGrey,
            ),
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
