import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.bill,
    required this.currencyCode,
    this.onTap,
    this.onMarkPaid,
  });

  final Bill bill;
  final String currencyCode;
  final VoidCallback? onTap;
  final VoidCallback? onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = Formatters(currencyCode);
    final statusColor = bill.statusColor(theme);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      bill.isPaid
                          ? 'Paid'
                          : bill.isOverdue
                              ? 'Overdue'
                              : 'Upcoming',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatter.currency(bill.amount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    formatter.date(bill.dueDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    categoryLabels[bill.category] ?? 'Other',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (!bill.isPaid && onMarkPaid != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onMarkPaid,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark paid'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
