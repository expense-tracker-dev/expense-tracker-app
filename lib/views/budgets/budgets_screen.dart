import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../categories/categories_screen.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

const Color _background = Color(0xFFFCF8EF);
const Color _gold = Color(0xFFD9AA2B);
const Color _darkGold = Color(0xFF795900);
const Color _text = Color(0xFF211F19);
const Color _muted = Color(0xFF887D67);
const Color _card = Colors.white;
const Color _expenseRed = Color(0xFFE98270);
const Color _incomeGreen = Color(0xFF6EAA91);

final RouteObserver<PageRoute<dynamic>> budgetRouteObserver =
RouteObserver<PageRoute<dynamic>>();

class MonthlyBudget {
  final String categoryId;
  final String categoryName;
  final int colorValue;
  final int iconCodePoint;
  final int month;
  final int year;
  final double limit;
  final double spent;

  const MonthlyBudget({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconCodePoint,
    required this.month,
    required this.year,
    required this.limit,
    this.spent = 0,
  });

  double get remaining => limit - spent;

  double get usedPercent => limit <= 0 ? 0 : spent / limit * 100;

  double get overAmount => spent > limit ? spent - limit : 0;

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'colorValue': colorValue,
    'iconCodePoint': iconCodePoint,
    'month': month,
    'year': year,
    'limit': limit,
    'spent': spent,
  };

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      colorValue: json['colorValue'] as int? ?? _gold.toARGB32(),
      iconCodePoint:
      json['iconCodePoint'] as int? ?? Icons.category.codePoint,
      month: json['month'] as int,
      year: json['year'] as int,
      limit: (json['limit'] as num).toDouble(),
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BudgetStorage {
  static const String _key = 'dailydhan_monthly_budgets';

  static Future<List<MonthlyBudget>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) return [];

    try {
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;

      return data
          .map(
            (item) => MonthlyBudget.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<MonthlyBudget> budgets) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _key,
      jsonEncode(budgets.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> saveBudget(MonthlyBudget budget) async {
    final all = await getAll();

    all.removeWhere(
          (item) =>
      item.categoryId == budget.categoryId &&
          item.month == budget.month &&
          item.year == budget.year,
    );

    all.add(budget);
    await saveAll(all);
  }

  static Future<void> removeBudget(MonthlyBudget budget) async {
    final all = await getAll();

    all.removeWhere(
          (item) =>
      item.categoryId == budget.categoryId &&
          item.month == budget.month &&
          item.year == budget.year,
    );

    await saveAll(all);
  }
}

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  BudgetsScreenState createState() => BudgetsScreenState();
}

// Public state class so main.dart can refresh the screen.
class BudgetsScreenState extends State<BudgetsScreen> with RouteAware {
  DateTime _selectedMonth = DateTime.now();

  List<CategoryItem> _categories = [];
  List<MonthlyBudget> _allBudgets = [];
  List<TransactionModel> _transactions = [];

  final TransactionService _transactionService = TransactionService();

  bool _loading = true;
  PageRoute<dynamic>? _subscribedRoute;

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _isPreviousMonth {
    final selected = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    return selected.isBefore(_currentMonth);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Call this method from main.dart to refresh budgets and transactions.
  Future<void> refreshData() async {
    await _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);

    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        budgetRouteObserver.unsubscribe(this);
      }

      _subscribedRoute = route;
      budgetRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    refreshData();
  }

  @override
  void dispose() {
    budgetRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CategoryService().getCategories(),
        BudgetStorage.getAll(),
        _transactionService.getTransactions(),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<CategoryItem>;
        _allBudgets = results[1] as List<MonthlyBudget>;
        _transactions = results[2] as List<TransactionModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('Unable to load budgets: $e');
    }
  }

  List<MonthlyBudget> get _monthBudgets {
    return _allBudgets
        .where(
          (budget) =>
      budget.month == _selectedMonth.month &&
          budget.year == _selectedMonth.year,
    )
        .toList();
  }

  List<CategoryItem> get _expenseCategories =>
      _categories.where((category) => !category.isIncome).toList();

  List<CategoryItem> get _budgetedCategories {
    final ids = _monthBudgets.map((budget) => budget.categoryId).toSet();

    return _expenseCategories
        .where((category) => ids.contains(category.id))
        .toList();
  }

  List<CategoryItem> get _unbudgetedCategories {
    final ids = _monthBudgets.map((budget) => budget.categoryId).toSet();

    return _expenseCategories
        .where((category) => !ids.contains(category.id))
        .toList();
  }

  double _spentFor(MonthlyBudget budget) {
    return _transactions
        .where(
          (transaction) =>
      !transaction.isIncome &&
          transaction.category.trim().toLowerCase() ==
              budget.categoryName.trim().toLowerCase() &&
          transaction.date.month == budget.month &&
          transaction.date.year == budget.year,
    )
        .fold<double>(
      0,
          (total, transaction) => total + transaction.amount,
    );
  }

  double get _totalBudget =>
      _monthBudgets.fold(0, (sum, budget) => sum + budget.limit);

  double get _totalSpent => _monthBudgets.fold<double>(
    0,
        (sum, budget) => sum + _spentFor(budget),
  );

  double get _totalRemaining => _totalBudget - _totalSpent;

  MonthlyBudget? _budgetFor(CategoryItem category) {
    for (final budget in _monthBudgets) {
      if (budget.categoryId == category.id) {
        return MonthlyBudget(
          categoryId: budget.categoryId,
          categoryName: budget.categoryName,
          colorValue: budget.colorValue,
          iconCodePoint: budget.iconCodePoint,
          month: budget.month,
          year: budget.year,
          limit: budget.limit,
          spent: _spentFor(budget),
        );
      }
    }

    return null;
  }

  String _money(double amount) {
    final negative = amount < 0;
    final value = amount.abs().toStringAsFixed(2);
    final parts = value.split('.');
    final digits = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;

      if (remaining > 0 &&
          (remaining == 3 ||
              (remaining > 3 && (remaining - 3) % 2 == 0))) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}₹${buffer.toString()}.${parts[1]}';
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  void _changeMonth(int difference) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + difference,
      );
    });
  }

  Future<void> _showBudgetDialog(CategoryItem category) async {
    if (_isPreviousMonth) {
      _message('You cannot add or edit budgets for previous months.');
      return;
    }

    final existing = _budgetFor(category);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _BudgetDialog(
          category: category,
          existing: existing,
          selectedMonth: _selectedMonth,
          onSave: (amount) async {
            if (_isPreviousMonth) {
              _message(
                'You cannot add or edit budgets for previous months.',
              );
              return;
            }

            final budget = MonthlyBudget(
              categoryId: category.id,
              categoryName: category.name,
              colorValue: category.colorValue,
              iconCodePoint: category.iconCodePoint,
              month: _selectedMonth.month,
              year: _selectedMonth.year,
              limit: amount,
              spent: existing == null ? 0 : _spentFor(existing),
            );

            await BudgetStorage.saveBudget(budget);

            if (!mounted) return;

            await _loadData();
            _message('Budget saved successfully.');
          },
        );
      },
    );
  }

  Future<void> _removeBudget(CategoryItem category) async {
    final budget = _budgetFor(category);
    if (budget == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _background,
        title: const Text(
          'Remove Budget?',
          style: TextStyle(fontSize: 18),
        ),
        content: Text(
          'Remove the budget for ${category.name} this month?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await BudgetStorage.removeBudget(budget);
    await _loadData();
    _message('Budget removed.');
  }

  Widget _categoryIcon(CategoryItem category, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category.icon,
        color: category.color,
        size: size * 0.52,
      ),
    );
  }

  Widget _monthSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: _gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: _darkGold,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthName(_selectedMonth),
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Spending Control',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final percentage =
    _totalBudget <= 0 ? 0.0 : (_totalSpent / _totalBudget * 100);
    final displayPercentage = percentage.clamp(0.0, 100.0);
    final overBudget = _totalSpent > _totalBudget && _totalBudget > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _darkGold.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL MONTHLY BUDGET',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _money(_totalBudget),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: displayPercentage / 100,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF0E8D8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overBudget ? _expenseRed : _gold,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _text,
                          ),
                        ),
                        const Text(
                          'Spent',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    _summaryAmount(
                      label: 'Spent so far',
                      amount: _totalSpent,
                      background: const Color(0xFFF5F0E6),
                      dotColor: _muted,
                    ),
                    const SizedBox(height: 8),
                    _summaryAmount(
                      label: _totalRemaining < 0
                          ? 'Over budget'
                          : 'Remaining',
                      amount: _totalRemaining.abs(),
                      background: _totalRemaining < 0
                          ? const Color(0xFFFFDAD5)
                          : const Color(0xFFFFEDC4),
                      dotColor: _totalRemaining < 0 ? _expenseRed : _gold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.track_changes, color: _darkGold, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _totalBudget == 0
                      ? 'Set a budget to track your spending'
                      : overBudget
                      ? 'Monthly budget exceeded'
                      : 'Daily run-rate: ${_money(_totalRemaining / DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day)}/day remaining',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              Text(
                _totalBudget == 0
                    ? 'No target'
                    : overBudget
                    ? 'Over Limit'
                    : 'On Target',
                style: TextStyle(
                  color: overBudget ? _expenseRed : _darkGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryAmount({
    required String label,
    required double amount,
    required Color background,
    required Color dotColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _money(amount),
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onAction,
    String actionLabel = '',
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onAction != null)
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 16),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _text,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetCard(CategoryItem category) {
    final budget = _budgetFor(category)!;
    final ratio = budget.limit <= 0
        ? 0.0
        : (budget.spent / budget.limit).clamp(0.0, 1.0);
    final exceeded = budget.spent > budget.limit;
    final approaching = !exceeded && budget.usedPercent >= 80;
    final remaining = budget.remaining;
    final percentageOver =
    budget.limit <= 0 ? 0.0 : (budget.overAmount / budget.limit * 100);

    final statusColor = exceeded
        ? const Color(0xFFFFDAD5)
        : approaching
        ? const Color(0xFFFFD875)
        : const Color(0xFFFFE2A0);

    final statusText = exceeded
        ? 'Exceeded by\n${_money(budget.overAmount)}'
        : approaching
        ? 'Approaching\nLimit'
        : 'Normal';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _categoryIcon(category, 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cap ${_money(budget.limit)} • ${budget.usedPercent.toStringAsFixed(0)}% used',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Container(
                constraints: const BoxConstraints(maxWidth: 112),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      exceeded
                          ? Icons.warning_amber_rounded
                          : approaching
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 13,
                      color: exceeded ? Colors.red : _darkGold,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: exceeded ? Colors.red.shade800 : _darkGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (exceeded) ...[
            const SizedBox(height: 12),
            Text(
              'Over budget by ${percentageOver.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (approaching) ...[
            const SizedBox(height: 12),
            Text(
              'Only ${_money(remaining)} remaining',
              style: const TextStyle(
                color: _darkGold,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: ratio,
              backgroundColor: const Color(0xFFF0E8D8),
              valueColor: AlwaysStoppedAnimation<Color>(
                exceeded ? Colors.red.shade700 : category.color,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining >= 0
                      ? '${_money(remaining)} remaining'
                      : '${_money(remaining.abs())} over limit',
                  style: TextStyle(
                    color: exceeded ? Colors.red : _darkGold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${_money(budget.spent)} / ${_money(budget.limit)}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly category limit',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: _isPreviousMonth
                    ? null
                    : () => _showBudgetDialog(category),
                child: Text(
                  'Adjust Limit',
                  style: TextStyle(
                    color: _isPreviousMonth ? _muted : _darkGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _removeBudget(category),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unbudgetedCard(CategoryItem category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _categoryIcon(category, 38),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isPreviousMonth
                ? null
                : () => _showBudgetDialog(category),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Set Budget'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _darkGold,
              disabledForegroundColor: _muted,
              side: const BorderSide(color: _gold),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              textStyle: const TextStyle(fontSize: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _muted, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgeted = _budgetedCategories;
    final unbudgeted = _unbudgetedCategories;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Budgets',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(color: _gold),
        )
            : RefreshIndicator(
          color: _gold,
          onRefresh: refreshData,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _monthSelector(),
              _summaryCard(),
              _sectionHeader(
                title: 'Budgeted Categories',
                subtitle:
                '${budgeted.length} categories with monthly limits',
              ),
              if (budgeted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _emptyState(
                    'No budgets set for this month. Add a budget to start tracking.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: budgeted.map(_budgetCard).toList(),
                  ),
                ),
              _sectionHeader(
                title: 'Not Budgeted This Month',
                subtitle:
                '${unbudgeted.length} expense categories without a limit',
              ),
              if (unbudgeted.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _emptyState(
                    'All expense categories have a budget for this month.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: unbudgeted.map(_unbudgetedCard).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  final CategoryItem category;
  final MonthlyBudget? existing;
  final DateTime selectedMonth;
  final Future<void> Function(double amount) onSave;

  const _BudgetDialog({
    required this.category,
    required this.existing,
    required this.selectedMonth,
    required this.onSave,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.limit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text(
        widget.existing == null ? 'Set Budget' : 'Adjust Budget',
        style: const TextStyle(
          color: _text,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.category.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.category.icon,
                  color: widget.category.color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _text,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            enabled: !_saving,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Monthly limit (₹)',
              labelStyle: const TextStyle(fontSize: 14),
              hintText: 'e.g. 5000',
              hintStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Budget for ${_monthName(widget.selectedMonth)}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: _text,
            textStyle: const TextStyle(fontSize: 14),
          ),
          onPressed: _saving
              ? null
              : () async {
            final amount = double.tryParse(_controller.text.trim());

            if (amount == null || !amount.isFinite || amount <= 0) {
              setState(() {
                _error = 'Enter a valid amount greater than zero.';
              });
              return;
            }

            setState(() {
              _saving = true;
              _error = null;
            });

            try {
              await widget.onSave(amount);

              if (mounted) {
                Navigator.pop(context);
              }
            } catch (_) {
              if (mounted) {
                setState(() {
                  _saving = false;
                  _error = 'Unable to save budget. Please try again.';
                });
              }
            }
          },
          child: Text(
            _saving
                ? 'Saving...'
                : widget.existing == null
                ? 'Add Budget'
                : 'Save Changes',
          ),
        ),
      ],
    );
  }
}