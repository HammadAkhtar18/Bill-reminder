import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../utils/constants.dart';

class BillFormScreen extends StatefulWidget {
  const BillFormScreen({super.key, this.bill});

  final Bill? bill;

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  BillCategory _category = BillCategory.utilities;
  RecurrenceType _recurrenceType = RecurrenceType.oneTime;
  int? _customIntervalDays;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    if (bill != null) {
      _nameController.text = bill.name;
      _amountController.text = bill.amount.toStringAsFixed(2);
      _notesController.text = bill.notes ?? '';
      _dueDate = bill.dueDate;
      _category = bill.category;
      _recurrenceType = bill.recurrenceType;
      _customIntervalDays = bill.customIntervalDays;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bill != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit bill' : 'Add bill'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Bill name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bill name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillCategory>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: BillCategory.values
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(categoryLabels[category] ?? 'Other'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RecurrenceType>(
                  value: _recurrenceType,
                  decoration: const InputDecoration(labelText: 'Recurrence'),
                  items: RecurrenceType.values
                      .map((recurrence) => DropdownMenuItem(
                            value: recurrence,
                            child: Text(recurrenceLabels[recurrence] ?? 'One-time'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _recurrenceType = value);
                  },
                ),
                if (_recurrenceType == RecurrenceType.custom) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _customIntervalDays?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Custom interval (days)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_recurrenceType != RecurrenceType.custom) return null;
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter valid number of days.';
                      }
                      return null;
                    },
                    onChanged: (value) => _customIntervalDays = int.tryParse(value),
                  ),
                ],
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due date'),
                  subtitle: Text(
                    '${_dueDate.toLocal()}'.split(' ').first,
                  ),
                  trailing: const Icon(Icons.date_range),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _saveBill(context),
                    child: Text(isEditing ? 'Save changes' : 'Add bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _saveBill(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<BillProvider>();
    final amount = double.parse(_amountController.text);

    final bill = Bill(
      id: widget.bill?.id,
      name: _nameController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      category: _category,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isPaid: widget.bill?.isPaid ?? false,
      paymentDate: widget.bill?.paymentDate,
      recurrenceType: _recurrenceType,
      customIntervalDays: _recurrenceType == RecurrenceType.custom ? _customIntervalDays : null,
    );

    if (widget.bill == null) {
      await provider.addBill(bill);
    } else {
      await provider.updateBill(bill);
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.bill == null ? 'Bill added.' : 'Bill updated.')),
    );
  }
}
