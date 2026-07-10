import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/donut_chart.dart';
import '../models/transaction_summary.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';

/// Analytics / Insights tab — spend breakdown by category for the current
/// month, sourced from GET /api/transactions/summary.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _transactionService = TransactionService();
  bool _isLoading = true;
  String? _error;
  TransactionSummary? _summary;

  static const _palette = [
    AppColors.primary,
    AppColors.gold,
    AppColors.income,
    AppColors.expense,
    AppColors.primaryLight,
    AppColors.goldDeep,
  ];

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
      final summary = await _transactionService.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load insights. Pull down to try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _isLoading
              ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [
                  SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                ])
              : _error != null
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                      SizedBox(
                        height: 300,
                        child: Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary))),
                      ),
                    ])
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final entries = summary.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <DonutSlice>[
      for (int i = 0; i < entries.length; i++)
        DonutSlice(label: entries[i].key, value: entries[i].value, color: _palette[i % _palette.length]),
    ];

    final monthChange = summary.previousMonthExpense > 0
        ? ((summary.totalExpense - summary.previousMonthExpense) / summary.previousMonthExpense) * 100
        : 0.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('This month vs last month', style: AppText.caption),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.subtle),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This Month', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    Text(formatCurrency(summary.totalExpense), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.expense)),
                    const SizedBox(height: 4),
                    Text('Last month: ${formatCurrency(summary.previousMonthExpense)}', style: AppText.caption),
                    if (summary.previousMonthExpense > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(monthChange <= 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 14, color: monthChange <= 0 ? AppColors.income : AppColors.expense),
                          const SizedBox(width: 2),
                          Text('${monthChange.abs().round()}% vs last month',
                              style: TextStyle(fontSize: 12, color: monthChange <= 0 ? AppColors.income : AppColors.expense, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  const Text('Income', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Text(formatCurrency(summary.totalIncome), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.income)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Spending by Category', style: AppText.sectionTitle),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.subtle),
          child: entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No expenses recorded this month yet.', style: TextStyle(color: AppColors.textSecondary))),
                )
              : Column(
                  children: [
                    DonutChart(slices: slices, size: 160, strokeWidth: 24),
                    const SizedBox(height: 20),
                    ...List.generate(entries.length, (i) {
                      final entry = entries[i];
                      final color = _palette[i % _palette.length];
                      final percent = summary.totalExpense > 0 ? (entry.value / summary.totalExpense) * 100 : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                            Text('${percent.round()}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 10),
                            Text(formatCurrency(entry.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
