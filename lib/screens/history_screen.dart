import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bill.dart';
import '../models/payment.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        if (provider.isLoading) {
          return const LoadingView();
        }

        final formatter = Formatters(settings.currencyCode);
        final payments = provider.payments;
        final billMap = {for (final bill in provider.bills) bill.id: bill};

        return RefreshIndicator(
          onRefresh: provider.loadBills,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: const Text('Payment history'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: payments.isEmpty
                        ? null
                        : () => _exportHistory(
                              context,
                              payments,
                              billMap,
                              settings.currencyCode,
                            ),
                  ),
                ],
              ),
              if (payments.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: 'No payments yet',
                    subtitle: 'Mark a bill as paid to start building your history.',
                    icon: Icons.history,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = payments[index];
                        final billName = billMap[payment.billId]?.name ?? 'Bill payment';
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.check)),
                            title: Text(billName),
                            subtitle: Text(
                              '${formatter.date(payment.paymentDate)} • ${formatter.currency(payment.amount)}',
                            ),
                          ),
                        );
                      },
                      childCount: payments.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportHistory(
    BuildContext context,
    List<Payment> payments,
    Map<int?, Bill> billMap,
    String currencyCode,
  ) async {
    final formatter = Formatters(currencyCode);
    final rows = <List<String>>[
      ['Bill', 'Amount', 'Payment Date', 'Currency'],
      ...payments.map((payment) => [
            billMap[payment.billId]?.name ?? 'Bill payment',
            formatter.currency(payment.amount),
            formatter.date(payment.paymentDate),
            currencyCode,
          ]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/payment_history.csv');
    await file.writeAsString(csvData);

    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: 'Payment history');
  }
}
