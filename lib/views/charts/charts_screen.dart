import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color green = Color(0xFF438A68);
  static const Color red = Color(0xFFC8463E);

  final TransactionService _service = TransactionService();

  List<TransactionModel> _transactions = [];
  String _period = 'Monthly';
  DateTime _selectedMonth = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _service.getTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  List<TransactionModel> get _filtered {
    return _transactions.where((t) {
      if (_period == 'Monthly') {
        return t.date.year == _selectedMonth.year &&
            t.date.month == _selectedMonth.month;
      }

      if (_period == 'Yearly') {
        return t.date.year == _selectedMonth.year;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));

      return !t.date.isBefore(start) &&
          !t.date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
    }).toList();
  }

  double get _income => _filtered
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _expenses => _filtered
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _total => _income - _expenses;

  Map<String, double> get _categoryTotals {
    final result = <String, double>{};

    for (final transaction in _filtered.where((t) => !t.isIncome)) {
      result.update(
        transaction.category,
            (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    return result;
  }

  List<MapEntry<String, double>> get _topCategories {
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(4).toList();
  }

  String _money(double value) {
    final amount = value.abs().toStringAsFixed(0);
    final formatted = amount.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );

    return '${value < 0 ? '-' : ''}₹$formatted';
  }

  String get _monthLabel {
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

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + amount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(color: gold),
        )
            : RefreshIndicator(
          color: gold,
          onRefresh: _loadTransactions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            children: [
              _periodSelector(),
              const SizedBox(height: 14),
              _monthHeader(),
              const SizedBox(height: 12),
              _summaryCards(),
              const SizedBox(height: 12),
              _cashFlowCard(),
              const SizedBox(height: 12),
              _categoryBreakdown(),
              const SizedBox(height: 12),
              _topCategoriesCard(),
              const SizedBox(height: 12),
              _insightCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE7DD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
          final selected = _period == period;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? darkGold : muted,
                    fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthHeader() {
    return Row(
      children: [
        const Icon(Icons.calendar_month, size: 19, color: darkGold),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _period == 'Weekly' ? 'Last 7 days' : _monthLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        if (_period == 'Monthly')
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 22),
            visualDensity: VisualDensity.compact,
          ),
        if (_period == 'Monthly')
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, size: 22),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _summaryCards() {
    final cards = [
      ('INCOME', _income, green),
      ('EXPENSES', _expenses, red),
      ('TOTAL', _total, darkGold),
    ];

    return Row(
      children: cards.asMap().entries.map((entry) {
        final item = entry.value;
        final label = item.$1;
        final amount = item.$2;
        final color = item.$3;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: entry.key == cards.length - 1 ? 0 : 6,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _money(amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _cashFlowCard() {
    final months = _lastSixMonths();
    double maxAmount = 1;

    for (final month in months) {
      final income = _sumForMonth(month, true);
      final expense = _sumForMonth(month, false);

      if (income > maxAmount) maxAmount = income;
      if (expense > maxAmount) maxAmount = expense;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Income vs Expenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 6 months cash flow',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: darkGold),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _period == 'Weekly' ? 'Last 7 days' : _monthLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  '+${_money(_income)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: green),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '-${_money(_expenses)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 122,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                final income = _sumForMonth(month, true);
                final expense = _sumForMonth(month, false);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _bar(income / maxAmount, green),
                            const SizedBox(width: 2),
                            _bar(expense / maxAmount, red),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _shortMonth(month.month),
                        style: const TextStyle(
                          fontSize: 10,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, Color color) {
    return Flexible(
      child: Container(
        width: 12,
        height: (value * 82).clamp(3.0, 82.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.82),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
      ),
    );
  }

  List<DateTime> _lastSixMonths() {
    return List.generate(
      6,
          (index) => DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 5 + index,
      ),
    );
  }

  double _sumForMonth(DateTime month, bool income) {
    return _transactions
        .where(
          (t) =>
      t.date.year == month.year &&
          t.date.month == month.month &&
          t.isIncome == income,
    )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String _shortMonth(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return names[month - 1];
  }

  Widget _categoryBreakdown() {
    final categories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent =
    categories.fold(0.0, (sum, item) => sum + item.value);

    final colors = [
      const Color(0xFF513829),
      const Color(0xFFD9AA2B),
      const Color(0xFFF3C95B),
      const Color(0xFFB88600),
      const Color(0xFF8D806D),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribution across expense categories',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 18,
                      color: Color(0xFFF0EDE4),
                    ),
                  ),
                  if (totalSpent > 0)
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: _DonutPainter(
                        values: categories.map((e) => e.value).toList(),
                        colors: colors,
                      ),
                    ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TOTAL SPENT',
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _money(totalSpent),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        '${_filtered.where((t) => !t.isIncome).length} Txns',
                        style: const TextStyle(
                          fontSize: 11,
                          color: darkGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: categories.take(5).toList().asMap().entries.map((entry) {
              final item = entry.value;
              final percent =
              totalSpent == 0 ? 0 : item.value / totalSpent * 100;

              return SizedBox(
                width: 135,
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${item.key} (${percent.toStringAsFixed(0)}%)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _topCategoriesCard() {
    final top = _topCategories;
    final maxAmount = top.isEmpty ? 1.0 : top.first.value;

    final colors = [
      const Color(0xFF513829),
      const Color(0xFFD9AA2B),
      const Color(0xFFF3C95B),
      const Color(0xFFB88600),
    ];

    final icons = [
      Icons.restaurant,
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.directions_car,
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ranked by overall spending impact',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Add expenses to see your top categories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
            )
          else
            ...top.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;

              final count = _filtered
                  .where(
                    (t) => !t.isIncome && t.category == category.key,
              )
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2EEE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            icons[index % icons.length],
                            size: 19,
                            color: colors[index % colors.length],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F0E8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            category.key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _money(category.value),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$count transactions',
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: category.value / maxAmount,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF0EDE4),
                        color: colors[index % colors.length],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _insightCard() {
    final total = _income + _expenses;
    final rate = total == 0 ? 0.0 : (_total / total * 100);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE8BD42),
            child: Icon(
              Icons.lightbulb_outline,
              color: darkGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mindful Discipline Insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _total >= 0
                      ? 'Your current net total is ${_money(_total)}. Your income minus expenses is ${rate.toStringAsFixed(1)}% of combined activity.'
                      : 'Your expenses exceed your income by ${_money(-_total)} for this period. Review your spending categories.',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF65573B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, value) => sum + value);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    var start = -1.57079632679;

    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 6.28318530718;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect.deflate(9), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.colors.length != colors.length) {
      return true;
    }

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }

    for (var i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i] != colors[i]) return true;
    }

    return false;
  }
}