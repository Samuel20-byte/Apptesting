import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ring_progress.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/transaction_summary.dart';
import '../services/account_service.dart';
import '../services/transaction_service.dart';
import '../services/goal_service.dart';
import '../utils/formatters.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

/// Home / Dashboard screen. Pulls together accounts, this month's income/
/// expense summary, the most recent transactions, and (if one exists) the
/// user's first savings goal.
class DashboardScreen extends StatefulWidget {
  final AppUser user;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onLogout;
  final ValueChanged<AppUser>? onUserUpdated;

  const DashboardScreen({
    super.key,
    required this.user,
    this.onNavigate,
    this.onLogout,
    this.onUserUpdated,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _accountService = AccountService();
  final _transactionService = TransactionService();
  final _goalService = GoalService();

  bool _isLoading = true;
  String? _error;

  double _currentBalance = 0;
  TransactionSummary? _summary;
  List<Transaction> _recentTransactions = [];
  Goal? _primaryGoal;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final accountsFuture = _accountService.getAccounts();
      final summaryFuture = _transactionService.getSummary();
      final recentFuture = _transactionService.getTransactions(limit: 3);
      final goalsFuture = _goalService.getGoals();

      final accounts = await accountsFuture;
      final summary = await summaryFuture;
      final recent = await recentFuture;
      final goals = await goalsFuture;

      double balance = 0;
      for (final a in accounts) {
        balance += a.balance;
      }

      if (!mounted) return;
      setState(() {
        _currentBalance = balance;
        _summary = summary;
        _recentTransactions = recent;
        _primaryGoal = goals.isNotEmpty ? goals.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your dashboard. Pull down to try again.';
        _isLoading = false;
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String? get _insightMessage {
    final s = _summary;
    if (s == null || s.previousMonthExpense <= 0) return null;
    final change =
        ((s.totalExpense - s.previousMonthExpense) / s.previousMonthExpense) * 100;
    if (change.abs() < 1) return null;
    if (change < 0) {
      return "You've spent ${change.abs().round()}% less than last month. Keep it up.";
    }
    return "You've spent ${change.round()}% more than last month.";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalIncome = _summary?.totalIncome ?? 0;
    final totalExpenses = _summary?.totalExpense ?? 0;
    final goal = _primaryGoal;
    final savingsProgress = goal?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$_greeting 👋',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(widget.user.fullName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen())),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_none_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final updated = await Navigator.of(context).push<AppUser>(
                                MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                        user: widget.user,
                                        onLogout: widget.onLogout ?? () {})),
                              );
                              if (updated != null) {
                                widget.onUserUpdated?.call(updated);
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(widget.user.initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Balance',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(formatCurrency(_currentBalance),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Updated just now',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      if (_insightMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.goldPale,
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_graph_rounded,
                                  color: AppColors.goldDeep, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _insightMessage!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.goldDeep,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              label: 'Total Income',
                              value: formatCurrency(totalIncome),
                              valueColor: AppColors.income,
                              icon: Icons.trending_up_rounded,
                              iconBackground: AppColors.incomePale,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              label: 'Total Expenses',
                              value: formatCurrency(totalExpenses),
                              valueColor: AppColors.expense,
                              icon: Icons.trending_down_rounded,
                              iconBackground: AppColors.expensePale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppShadows.subtle),
                        child: Row(
                          children: [
                            RingProgress(
                              progress: savingsProgress,
                              size: 64,
                              strokeWidth: 8,
                              color: AppColors.gold,
                              trackColor: AppColors.goldPale,
                              center: Text('${(savingsProgress * 100).round()}%',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldDeep)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Savings Goal',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(
                                      goal == null
                                          ? 'Set a savings goal in Budget Planner'
                                          : '${formatCurrency(goal.currentAmount)} saved',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  if (goal != null)
                                    Text('Target: ${formatCurrency(goal.targetAmount)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Quick Actions', style: AppText.sectionTitle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onNavigate?.call(1),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Transaction'),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => widget.onNavigate?.call(3),
                              icon: const Icon(Icons.pie_chart_outline_rounded,
                                  size: 18),
                              label: const Text('Budget Planner'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.border),
                                backgroundColor: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Transactions',
                              style: AppText.sectionTitle),
                          GestureDetector(
                            onTap: () => widget.onNavigate?.call(1),
                            child: const Row(
                              children: [
                                Text('See all',
                                    style: TextStyle(
                                        color: AppColors.primary, fontSize: 13)),
                                Icon(Icons.chevron_right,
                                    color: AppColors.primary, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_recentTransactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No transactions yet — add your first one!',
                              style: AppText.caption),
                        )
                      else
                        ..._recentTransactions
                            .map((tx) => _TransactionTile(tx: tx)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? AppColors.income : AppColors.expense;
    return Container(
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
                color:
                    tx.isIncome ? AppColors.incomePale : AppColors.expensePale,
                shape: BoxShape.circle),
            child: Icon(
                tx.isIncome
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.categoryName ?? tx.description ?? 'Transaction',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text(
                    tx.transactionDate != null
                        ? formatDate(tx.transactionDate!)
                        : '',
                    style: AppText.caption),
              ],
            ),
          ),
          Text(
              formatSignedCurrency(tx.isIncome ? tx.amount : -tx.amount),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
