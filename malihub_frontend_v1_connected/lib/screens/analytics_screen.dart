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

  // Dedicated categorical palette — deliberately independent from
  // AppColors.income/expense (which mean "money in/out" elsewhere in the
  // app) and from primaryLight/goldDeep (which are just lighter shades of
  // primary/gold, not distinct hues). Eight genuinely different hues —
  // more than the categories currently in use, so there's headroom before
  // any repeat is even possible.
  static const _palette = [
    AppColors.primary, // forest green (brand)
    AppColors.gold, // amber/gold (brand)
    Color(0xFF3B6FA6), // slate blue
    Color(0xFFB5563A), // terracotta
    Color(0xFF3E8E7E), // teal
    Color(0xFF8C5C99), // plum
    Color(0xFF8B3A42), // maroon
    Color(0xFF2E3F6E), // navy
  ];

  /// Assigns each category a color based on its alphabetical position among
  /// ALL currently known categories — not a hash, and not its rank by spend
  /// amount. Unlike hashing, this guarantees no two categories ever share a
  /// color (as long as there are 8 or fewer categories, matching the
  /// palette size above). Amounts changing between transactions no longer
  /// affects this at all, since it doesn't depend on value.
  Map<String, Color> _buildCategoryColors(Iterable<String> categoryNames) {
    final sorted = categoryNames.toSet().toList()..sort();
    return {
      for (int i = 0; i < sorted.length; i++)
        sorted[i]: _palette[i % _palette.length],
    };
  }

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
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                      SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator())),
                    ])
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary))),
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
    final categoryColors = _buildCategoryColors(summary.byCategory.keys);
    final slices = <DonutSlice>[
      for (final entry in entries)
        DonutSlice(
            label: entry.key,
            value: entry.value,
            color: categoryColors[entry.key]!),
    ];

    final monthChange = summary.previousMonthExpense > 0
        ? ((summary.totalExpense - summary.previousMonthExpense) /
                summary.previousMonthExpense) *
            100
        : 0.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Insights',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('This month vs last month', style: AppText.caption),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.subtle),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This Month', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    Text(formatCurrency(summary.totalExpense),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.expense)),
                    const SizedBox(height: 4),
                    Text(
                        'Last month: ${formatCurrency(summary.previousMonthExpense)}',
                        style: AppText.caption),
                    if (summary.previousMonthExpense > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                              monthChange <= 0
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 14,
                              color: monthChange <= 0
                                  ? AppColors.income
                                  : AppColors.expense),
                          const SizedBox(width: 2),
                          Text('${monthChange.abs().round()}% vs last month',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: monthChange <= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontWeight: FontWeight.w600)),
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
                  Text(formatCurrency(summary.totalIncome),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.income)),
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
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppShadows.subtle),
          child: entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text('No expenses recorded this month yet.',
                          style: TextStyle(color: AppColors.textSecondary))),
                )
              : Column(
                  children: [
                    DonutChart(slices: slices, size: 160, strokeWidth: 24),
                    const SizedBox(height: 20),
                    ...List.generate(entries.length, (i) {
                      final entry = entries[i];
                      final color = categoryColors[entry.key]!;
                      final percent = summary.totalExpense > 0
                          ? (entry.value / summary.totalExpense) * 100
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(entry.key,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary))),
                            Text('${percent.round()}%',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(width: 10),
                            Text(formatCurrency(entry.value),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
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
