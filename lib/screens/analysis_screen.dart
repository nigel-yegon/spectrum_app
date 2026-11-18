import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../models/unit.dart';
import '../providers/app_state.dart';

const _green = Color(0xFF1E3A2F);
const _accent = Color(0xFF2E7D5E);
const _cream = Color(0xFFF9F9F6);

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _months = 6;

  String _money(num value) {
    return NumberFormat.currency(
      symbol: 'KSh ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Only confirmed payments count as collected income.
    final confirmed = state.payments
        .where((p) => p.status == PaymentStatus.confirmed)
        .toList();

    final now = DateTime.now();

    // Generate monthly income data for the selected period.
    final monthly = List.generate(_months, (i) {
      final month = DateTime(now.year, now.month - (_months - 1 - i), 1);

      final income = confirmed
          .where(
            (p) =>
                p.paymentDate.year == month.year &&
                p.paymentDate.month == month.month,
          )
          .fold<double>(0, (sum, p) => sum + p.amount);

      return (month: month, income: income);
    });

    final totalIncome = monthly.fold<double>(
      0,
      (sum, item) => sum + item.income,
    );

    // Unit occupancy metrics.
    final occupied = state.units
        .where((u) => u.status == UnitStatus.occupied)
        .length;

    final vacant = state.units
        .where((u) => u.status == UnitStatus.vacant)
        .length;

    final maintenance = state.units
        .where((u) => u.status == UnitStatus.maintenance)
        .length;

    final totalUnits = state.units.length;

    final occupancy = totalUnits == 0 ? 0.0 : occupied / totalUnits * 100;

    // Income grouped by payment method.
    final methods = PaymentMethod.values
        .map((method) {
          final total = confirmed
              .where((p) => p.method == method)
              .fold<double>(0, (sum, p) => sum + p.amount);

          return (method: method, total: total);
        })
        .where((entry) => entry.total > 0)
        .toList();

    final totalMethodIncome = methods.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    final maxIncome = monthly.fold<double>(
      0,
      (max, item) => item.income > max ? item.income : max,
    );

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: _cream,
        foregroundColor: _green,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: state.loadAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // INCOME OVERVIEW
            _sectionTitle('Income overview'),
            const SizedBox(height: 12),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Confirmed income',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      DropdownButton<int>(
                        value: _months,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 months')),
                          DropdownMenuItem(value: 6, child: Text('6 months')),
                          DropdownMenuItem(value: 12, child: Text('12 months')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _months = value);
                          }
                        },
                      ),
                    ],
                  ),

                  Text(
                    _money(totalIncome),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 220,
                    child: monthly.every((m) => m.income == 0)
                        ? const _EmptyChart(
                            message: 'No confirmed income in this period.',
                          )
                        : LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxIncome <= 0 ? 100 : maxIncome * 1.2,

                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),

                              borderData: FlBorderData(show: false),

                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),

                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 48,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value == 0
                                            ? '0'
                                            : NumberFormat.compact().format(
                                                value,
                                              ),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),

                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();

                                      if (index < 0 ||
                                          index >= monthly.length) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('MMM')
                                              .format(monthly[index].month),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var i = 0; i < monthly.length; i++)
                                      FlSpot(i.toDouble(), monthly[i].income),
                                  ],
                                  isCurved: true,
                                  barWidth: 3,
                                  color: _accent,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: _accent.withOpacity(0.12),
                                  ),
                                ),
                              ],
                            ),

                            // Correct fl_chart animation parameters.
                          //   swapAnimationDuration: const Duration(
                          //     milliseconds: 700,
                          //   ),
                          //   swapAnimationCurve: Curves.easeInOut,
                           ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PORTFOLIO PERFORMANCE
            _sectionTitle('Portfolio performance'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _metric(
                    'Occupancy',
                    '${occupancy.toStringAsFixed(1)}%',
                    Icons.apartment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metric(
                    'Occupied units',
                    '$occupied',
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unit distribution',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  if (totalUnits == 0)
                    const _EmptyChart(message: 'No units have been added yet.')
                  else
                    SizedBox(
                      height: 170,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 35,
                                sections: [
                                  _pieSection(occupied, _accent),
                                  _pieSection(vacant, Colors.orange),
                                  _pieSection(maintenance, Colors.blueGrey),
                                ],
                              ),

                              // Correct fl_chart animation parameters.
                              swapAnimationDuration: const Duration(
                                milliseconds: 700,
                              ),
                              swapAnimationCurve: Curves.easeInOut,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legend('Occupied', occupied, _accent),
                              _legend('Vacant', vacant, Colors.orange),
                              _legend(
                                'Maintenance',
                                maintenance,
                                Colors.blueGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // PAYMENT METHOD ANALYSIS
            _sectionTitle('Income by payment method'),
            const SizedBox(height: 12),

            _card(
              child: methods.isEmpty
                  ? const _EmptyChart(
                      message: 'No confirmed payments to analyse.',
                    )
                  : Column(
                      children: methods.map((entry) {
                        final ratio = totalMethodIncome == 0
                            ? 0.0
                            : entry.total / totalMethodIncome;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_methodName(entry.method)),
                                  Text(
                                    _money(entry.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 9,
                                  backgroundColor: Colors.grey.shade200,
                                  color: _accent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // PROPERTY INCOME
            _sectionTitle('Property income'),
            const SizedBox(height: 12),

            _card(
              child: state.properties.isEmpty
                  ? const _EmptyChart(
                      message: 'Add properties to see performance here.',
                    )
                  : Column(
                      children: state.properties.map((property) {
                        final unitIds = state.units
                            .where((u) => u.propertyId == property.id)
                            .map((u) => u.id)
                            .toSet();

                        final income = confirmed
                            .where((p) => unitIds.contains(p.unitId))
                            .fold<double>(0, (sum, p) => sum + p.amount);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(property.name),
                          subtitle: Text(
                            '${unitIds.length} units',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            _money(income),
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // PIE CHART SECTION
  PieChartSectionData _pieSection(int count, Color color) {
    return PieChartSectionData(
      value: count.toDouble(),
      color: color,
      radius: 25,
      showTitle: false,
    );
  }

  // CHART LEGEND
  Widget _legend(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text('$label ($value)', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // SECTION HEADING
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _green,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // CARD CONTAINER
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  // METRIC CARD
  Widget _metric(String label, String value, IconData icon) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // PAYMENT METHOD LABELS
  String _methodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.cheque:
        return 'Cheque';
    }
  }
}

// EMPTY CHART STATE
class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
