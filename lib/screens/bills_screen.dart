import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/bill_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_view.dart';
import 'bill_form_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String _searchQuery = '';
  BillCategory? _categoryFilter;
  bool? _paidFilter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return Consumer2<BillProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        if (provider.isLoading) {
          return const LoadingView();
        }

        final filteredBills = provider.bills.where((bill) {
          final matchesSearch = bill.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _categoryFilter == null || bill.category == _categoryFilter;
          final matchesPaid = _paidFilter == null || bill.isPaid == _paidFilter;
          final matchesDate = _dateRange == null ||
              (bill.dueDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                  bill.dueDate.isBefore(_dateRange!.end.add(const Duration(days: 1))));
          return matchesSearch && matchesCategory && matchesPaid && matchesDate;
        }).toList();

        return RefreshIndicator(
          onRefresh: provider.loadBills,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: const Text('Bills'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(76),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search bills',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
              ),
              if (filteredBills.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    title: 'No bills found',
                    subtitle: 'Try adjusting your filters or add a new bill.',
                    icon: Icons.receipt_long,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bill = filteredBills[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey(bill.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _confirmDelete(context, bill),
                            onDismissed: (_) async {
                              await provider.deleteBill(bill);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bill deleted.')),
                              );
                            },
                            child: BillCard(
                              bill: bill,
                              currencyCode: settings.currencyCode,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BillFormScreen(bill: bill),
                                  ),
                                );
                              },
                              onMarkPaid: bill.isPaid
                                  ? null
                                  : () => _markPaid(context, bill),
                            ),
                          ),
                        );
                      },
                      childCount: filteredBills.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markPaid(BuildContext context, Bill bill) async {
    final provider = context.read<BillProvider>();
    final paymentDate = DateTime.now();
    await provider.markBillPaid(bill, paymentDate);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill marked as paid.')),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: BillCategory.values.map((category) {
                      return ChoiceChip(
                        label: Text(categoryLabels[category] ?? 'Other'),
                        selected: _categoryFilter == category,
                        onSelected: (selected) {
                          setModalState(() {
                            _categoryFilter = selected ? category : null;
                          });
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Status', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Paid'),
                        selected: _paidFilter == true,
                        onSelected: (selected) {
                          setModalState(() => _paidFilter = selected ? true : null);
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Unpaid'),
                        selected: _paidFilter == false,
                        onSelected: (selected) {
                          setModalState(() => _paidFilter = selected ? false : null);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date range'),
                    subtitle: Text(
                      _dateRange == null
                          ? 'All dates'
                          : '${_dateRange!.start.toString().split(' ').first} - ${_dateRange!.end.toString().split(' ').first}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: _dateRange,
                        );
                        if (range != null) {
                          setModalState(() => _dateRange = range);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _categoryFilter = null;
                            _paidFilter = null;
                            _dateRange = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Bill bill) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete bill?'),
          content: Text('This will remove ${bill.name} and its payment history.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
