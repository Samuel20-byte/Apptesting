import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/app_text_field.dart';
import '../widgets/ring_progress.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/category.dart';
import '../services/budget_service.dart';
import '../services/goal_service.dart';
import '../services/category_service.dart';
import '../services/api_exception.dart';
import '../utils/formatters.dart';

/// Budget Planner tab: per-category budgets (from GET /api/budgets, which
/// already computes spent/remaining/percent_used server-side) plus a single
/// savings goal card. The schema has no single "overall monthly budget"
/// entity, so the top summary card is a computed sum across all category
/// budgets rather than a separately editable field.
class BudgetPlannerScreen extends StatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  State<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends State<BudgetPlannerScreen> {
  final _budgetService = BudgetService();
  final _goalService = GoalService();
  final _categoryService = CategoryService();

  bool _isLoading = true;
  String? _error;
  List<Budget> _budgets = [];
  List<Goal> _goals = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final budgets = await _budgetService.getBudgets();
      final goals = await _goalService.getGoals();
      final categories = await _categoryService.getCategories();
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _goals = goals;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your budgets. Pull down to try again.';
        _isLoading = false;
      });
    }
  }

  List<Category> get _categoriesWithoutBudget {
    final used = _budgets.map((b) => b.categoryId).toSet();
    return _categories.where((c) => !used.contains(c.categoryId)).toList();
  }

  Future<void> _addBudget() async {
    final available = _categoriesWithoutBudget;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All categories already have a budget.')));
      return;
    }
    Category selected = available.first;
    final amountController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add category budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Category>(
                initialValue: selected,
                items: available.map((c) => DropdownMenuItem(value: c, child: Text(c.categoryName))).toList(),
                onChanged: (v) => setDialogState(() => selected = v ?? selected),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Monthly budget (KES)',
                hint: '0.00',
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    try {
      await _budgetService.createBudget(
        categoryId: selected.categoryId,
        budgetAmount: amount,
        periodType: 'monthly',
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _editBudget(Budget budget) async {
    final amountController = TextEditingController(text: budget.budgetAmount.toStringAsFixed(0));

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(budget.categoryName ?? 'Edit budget'),
        content: AppTextField(
          label: 'Monthly budget (KES)',
          hint: '0.00',
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(false);
              await _confirmDeleteBudget(budget);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expense)),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    try {
      await _budgetService.updateBudget(budgetId: budget.budgetId, budgetAmount: amount);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _confirmDeleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove budget'),
        content: Text('Remove the budget for ${budget.categoryName ?? 'this category'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _budgetService.deleteBudget(budget.budgetId);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  Future<void> _editGoal() async {
    final hasGoal = _goals.isNotEmpty;
    final goal = hasGoal ? _goals.first : null;
    final nameController = TextEditingController(text: goal?.goalName ?? 'Savings Goal');
    final targetController = TextEditingController(text: goal != null ? goal.targetAmount.toStringAsFixed(0) : '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(hasGoal ? 'Edit savings goal' : 'Create savings goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Goal name', hint: 'e.g. Emergency Fund', controller: nameController),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Target amount (KES)',
              hint: '0.00',
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;
    final target = double.tryParse(targetController.text.trim());
    if (target == null || target <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid target amount')));
      return;
    }

    try {
      if (hasGoal) {
        await _goalService.updateGoal(goalId: goal!.goalId, goalName: nameController.text.trim(), targetAmount: target);
      } else {
        await _goalService.createGoal(goalName: nameController.text.trim(), targetAmount: target);
      }
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach the server.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudget,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                  SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                ])
              : _error != null
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                      SizedBox(height: 300, child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))),
                    ])
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final totalBudget = _budgets.fold<double>(0, (sum, b) => sum + b.budgetAmount);
    final totalSpent = _budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final overallPercent = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final goal = _goals.isNotEmpty ? _goals.first : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        const Text('Budget Planner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('This month across all categories', style: AppText.caption),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Budget', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(formatCurrency(totalBudget), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overallPercent,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(overallPercent > 0.9 ? AppColors.expense : AppColors.gold),
                ),
              ),
              const SizedBox(height: 8),
              Text('${formatCurrency(totalSpent)} spent of ${formatCurrency(totalBudget)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Category Budgets', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        if (_budgets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No category budgets yet — tap + to add one.', style: AppText.caption),
          )
        else
          ..._budgets.map((b) => _BudgetCard(budget: b, onTap: () => _editBudget(b))),
        const SizedBox(height: 20),
        const Text('Savings Goal', style: AppText.sectionTitle),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.subtle),
          child: goal == null
              ? Column(
                  children: [
                    const Text('No savings goal set yet.', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _editGoal, child: const Text('Create a goal')),
                  ],
                )
              : InkWell(
                  onTap: _editGoal,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      RingProgress(
                        progress: goal.progress,
                        size: 64,
                        strokeWidth: 8,
                        color: AppColors.gold,
                        trackColor: AppColors.goldPale,
                        center: Text('${(goal.progress * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.goldDeep)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.goalName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('${formatCurrency(goal.currentAmount)} of ${formatCurrency(goal.targetAmount)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;

  const _BudgetCard({required this.budget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overBudget = budget.percentUsed >= 100;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.subtle),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(budget.categoryName ?? 'Category', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                Text('${formatCurrency(budget.spent)} / ${formatCurrency(budget.budgetAmount)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: overBudget ? AppColors.expense : AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (budget.percentUsed / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(overBudget ? AppColors.expense : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
