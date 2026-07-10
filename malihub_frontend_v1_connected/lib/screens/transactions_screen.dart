import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_text_field.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/account_service.dart';
import '../services/transaction_service.dart';
import '../services/api_exception.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

/// Transactions screen: Add Income / Add Expense / History.
///
/// Note on categories: the schema has a single `categories` table shared
/// across income and expense (the 5 defaults seeded at registration mix
/// both — e.g. "Salary" alongside "Groceries"). Both tabs below use the
/// same category list rather than maintaining a separate income-sources
/// list, to stay consistent with that schema.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _tabIndex = 0;

  final _categoryService = CategoryService();
  final _accountService = AccountService();
  final _transactionService = TransactionService();

  bool _isLoadingContext = true;
  String? _contextError;
  List<Category> _categories = [];
  Account? _account;

  bool _isLoadingHistory = true;
  String? _historyError;
  List<Transaction> _history = [];

  @override
  void initState() {
    super.initState();
    _loadFormContext();
    _loadHistory();
  }

  Future<void> _loadFormContext() async {
    setState(() {
      _isLoadingContext = true;
      _contextError = null;
    });
    try {
      final categories = await _categoryService.getCategories();
      final account = await _accountService.ensureDefaultAccount();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _account = account;
        _isLoadingContext = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contextError = 'Could not load categories. Pull down on History to retry, or reopen this tab.';
        _isLoadingContext = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final history = await _transactionService.getTransactions();
      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Could not load transaction history.';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _handleSave({
    required bool isIncome,
    required int categoryId,
    required double amount,
    required DateTime date,
    required String note,
  }) async {
    if (_account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found — try reopening this screen.')));
      return;
    }
    try {
      await _transactionService.createTransaction(
        accountId: _account!.accountId,
        categoryId: categoryId,
        amount: amount,
        transactionType: isIncome ? 'credit' : 'debit',
        description: note,
        transactionDate: date,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${isIncome ? 'Income' : 'Expense'} saved')));
      setState(() => _tabIndex = 2);
      _loadHistory();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Text('Transactions',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary))
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentedTabs(
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tabIndex == 2
                  ? RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: _buildHistory(),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildForm(isIncome: _tabIndex == 0),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({required bool isIncome}) {
    if (_isLoadingContext) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_contextError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(_contextError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadFormContext, child: const Text('Retry')),
          ],
        ),
      );
    }
    return _TransactionForm(
      key: ValueKey(isIncome),
      isIncome: isIncome,
      categories: _categories,
      onSave: (categoryId, amount, date, note) => _handleSave(
        isIncome: isIncome,
        categoryId: categoryId,
        amount: amount,
        date: date,
        note: note,
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        ],
      );
    }
    if (_historyError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(_historyError!, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      );
    }
    if (_history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
            child: Center(
              child: Text('No transactions yet.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final tx = _history[i];
        final color = tx.isIncome ? AppColors.income : AppColors.expense;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            ));
            if (result == true) _loadHistory();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppShadows.subtle),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: tx.isIncome ? AppColors.incomePale : AppColors.expensePale,
                      shape: BoxShape.circle),
                  child: Icon(
                      tx.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 18,
                      color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.categoryName ?? 'Uncategorised',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary)),
                      Text(tx.transactionDate != null ? formatDate(tx.transactionDate!) : '',
                          style: AppText.caption),
                    ],
                  ),
                ),
                Text(formatSignedCurrency(tx.isIncome ? tx.amount : -tx.amount),
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Income', 'Expense', 'History'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.subtle),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

typedef _SaveTransaction = Future<void> Function(
    int categoryId, double amount, DateTime date, String note);

class _TransactionForm extends StatefulWidget {
  final bool isIncome;
  final List<Category> categories;
  final _SaveTransaction onSave;

  const _TransactionForm({
    super.key,
    required this.isIncome,
    required this.categories,
    required this.onSave,
  });

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year - 2),
        lastDate: DateTime(now.year + 2));
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = formatShortDate(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Select a ${widget.isIncome ? 'source' : 'category'}')));
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(
      _selectedCategory!.categoryId,
      amount,
      _selectedDate ?? DateTime.now(),
      _noteController.text.trim(),
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isIncome ? AppColors.income : AppColors.expense;
    final accentPale =
        widget.isIncome ? AppColors.incomePale : AppColors.expensePale;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.subtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration:
                    BoxDecoration(color: accentPale, shape: BoxShape.circle),
                child: Icon(
                    widget.isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: accentColor),
              ),
              const SizedBox(width: 8),
              Text('Add ${widget.isIncome ? 'Income' : 'Expense'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          AppTextField(
              label: 'Amount (KES)',
              hint: '0.00',
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          Text(widget.isIncome ? 'SOURCE' : 'CATEGORY', style: AppText.eyebrow),
          const SizedBox(height: 6),
          DropdownButtonFormField<Category>(
            initialValue: _selectedCategory,
            hint: Text(widget.isIncome ? 'Select source' : 'Select category'),
            items: widget.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c.categoryName)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          const Text('DATE', style: AppText.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: const InputDecoration(
                hintText: 'mm/dd/yyyy',
                suffixIcon: Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 16),
          AppTextField(
              label: 'Note (optional)',
              hint: 'e.g. Emergency Fund top-up',
              controller: _noteController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.isIncome
                    ? AppColors.primaryLight
                    : AppColors.expense),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Save ${widget.isIncome ? 'Income' : 'Expense'}'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
