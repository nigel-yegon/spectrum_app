
import 'package:flutter/material.dart';

import 'analysis_screen.dart';
import 'reports_screen.dart';

const _insightsGreen = Color(0xFF1E3A2F);
const _insightsCream = Color(0xFFF9F9F6);

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _insightsCream,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: _insightsCream,
        foregroundColor: _insightsGreen,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Understand your portfolio',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: _insightsGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explore financial performance, occupancy and transaction reports.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _InsightCard(
            icon: Icons.query_stats_rounded,
            title: 'Analysis',
            description:
            'Visualise monthly income, occupancy, payment methods and property performance.',
            action: 'View analysis',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnalysisScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InsightCard(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Reports',
            description:
            'Search transactions, filter by status and date, sort records and export PDFs.',
            action: 'Open reports',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _insightsGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: _insightsGreen,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      color: _insightsGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: _insightsGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
