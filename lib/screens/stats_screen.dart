import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        final billMap = {for (final bill in provider.bills) bill.id: bill};
        final categoryTotals = <BillCategory, double>{};

        for (final payment in provider.payments) {
          final bill = billMap[payment.billId];
          final category = bill?.category ?? BillCategory.other;
          categoryTotals[category] =
              (categoryTotals[category] ?? 0) + payment.amount;
        }

        final formatter = Formatters(settings.currencyCode);
        final totalSpent = categoryTotals.values.fold<double>(0, (sum, item) => sum + item);

        return Scaffold(
          appBar: AppBar(title: const Text('Insights')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: categoryTotals.isEmpty
                ? const EmptyState(
                    title: 'No data yet',
                    subtitle: 'Record payments to unlock insights by category.',
                    icon: Icons.pie_chart_outline,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending by category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total spent: ${formatter.currency(totalSpent)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: _buildSections(categoryTotals),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: categoryTotals.entries.map((entry) {
                          return _LegendChip(
                            color: _categoryColor(entry.key),
                            label:
                                '${categoryLabels[entry.key]} (${formatter.currency(entry.value)})',
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<BillCategory, double> categoryTotals,
  ) {
    return categoryTotals.entries.map((entry) {
      return PieChartSectionData(
        color: _categoryColor(entry.key),
        value: entry.value,
        radius: 80,
        title: '',
      );
    }).toList();
  }

  Color _categoryColor(BillCategory category) {
    switch (category) {
      case BillCategory.utilities:
        return Colors.blue.shade400;
      case BillCategory.rent:
        return Colors.green.shade400;
      case BillCategory.subscription:
        return Colors.indigo.shade400;
      case BillCategory.creditCard:
        return Colors.orange.shade400;
      case BillCategory.insurance:
        return Colors.teal.shade400;
      case BillCategory.other:
      default:
        return Colors.grey.shade400;
    }
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(label),
    );
  }
}
