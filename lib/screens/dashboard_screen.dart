import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import '../widgets/bill_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        if (provider.isLoading) {
          return const LoadingView();
        }

        final formatter = Formatters(settings.currencyCode);
        final upcoming = provider.upcomingBills();
        final overdue = provider.overdueBills();
        final totalDue = provider.totalDueThisMonth();

        return RefreshIndicator(
          onRefresh: provider.loadBills,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: const Text('Dashboard'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.insights),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StatsScreen()),
                      );
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total due',
                              value: formatter.currency(totalDue),
                              icon: Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Overdue',
                              value: '${overdue.length} bills',
                              icon: Icons.warning_amber_rounded,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _BillSection(
                title: 'Upcoming (next 7 days)',
                bills: upcoming,
                currencyCode: settings.currencyCode,
                emptyTitle: 'No upcoming bills',
                emptySubtitle: 'Bills due soon will appear here for quick access.',
              ),
              _BillSection(
                title: 'Overdue bills',
                bills: overdue,
                currencyCode: settings.currencyCode,
                emptyTitle: 'No overdue bills',
                emptySubtitle: 'You are all caught up. Nice work!',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BillSection extends StatelessWidget {
  const _BillSection({
    required this.title,
    required this.bills,
    required this.currencyCode,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final String title;
  final List<Bill> bills;
  final String currencyCode;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (bills.isEmpty)
              SizedBox(
                height: 200,
                child: EmptyState(
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                  icon: Icons.event_available,
                ),
              )
            else
              Column(
                children: bills
                    .map<Widget>((bill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BillCard(
                            bill: bill,
                            currencyCode: currencyCode,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
