import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_text_field.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/api_exception.dart';
import '../utils/formatters.dart';

/// Detail view for a single transaction, reached by tapping a row in
/// Transaction History. Pops with `true` if the transaction was edited or
/// deleted, so History knows to refresh.
class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _transactionService = TransactionService();
  late Transaction _tx;
  bool _changed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete transaction'),
        content: const Text('This will remove the transaction. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _transactionService.deleteTransaction(_tx.transactionId);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      setState(() => _busy = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _editTransaction(BuildContext context) async {
    final amountController = TextEditingController(text: _tx.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: _tx.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Amount (KES)',
              hint: '0.00',
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            AppTextField(label: 'Note', hint: 'Optional note', controller: noteController),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _busy = true);
    try {
      final updated = await _transactionService.updateTransaction(
        transactionId: _tx.transactionId,
        amount: amount,
        description: noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _tx = updated;
        _changed = true;
        _busy = false;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction updated')));
    } on ApiException catch (e) {
      setState(() => _busy = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      setState(() => _busy = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _tx.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final bg = isIncome ? AppColors.incomePale : AppColors.expensePale;
    final title = _tx.categoryName ?? (_tx.description?.isNotEmpty == true ? _tx.description! : 'Transaction');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(_changed),
                  ),
                  const Text('Transaction', style: AppText.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: AppShadows.subtle),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 26),
                        ),
                        const SizedBox(height: 16),
                        Text(formatSignedCurrency(isIncome ? _tx.amount : -_tx.amount),
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: color)),
                        const SizedBox(height: 4),
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(label: 'Category', value: _tx.categoryName ?? '—'),
                  _DetailRow(label: 'Date', value: _tx.transactionDate != null ? formatDate(_tx.transactionDate!) : '—'),
                  _DetailRow(label: 'Type', value: isIncome ? 'Income' : 'Expense'),
                  if (_tx.description != null && _tx.description!.isNotEmpty)
                    _DetailRow(label: 'Note', value: _tx.description!),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _editTransaction(context),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit transaction'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: AppColors.border)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _confirmDelete(context),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                    label: const Text('Delete transaction', style: TextStyle(color: AppColors.expense)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: AppColors.expensePale)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
