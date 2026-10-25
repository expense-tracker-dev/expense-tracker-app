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
  DateTime _selectedWeekStart = _startOfWeek(DateTime.now());
  bool _loading = true;

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();

    TransactionService.transactionUpdates.addListener(
      _onTransactionsUpdated,
    );
  }

  void _onTransactionsUpdated() {
    _loadTransactions();
  }

  @override
  void dispose() {
    TransactionService.transactionUpdates.removeListener(
      _onTransactionsUpdated,
    );
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _service.getTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load transactions: $e')),
      );
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

      final end = _selectedWeekStart.add(const Duration(days: 7));

      return !t.date.isBefore(_selectedWeekStart) && t.date.isBefore(end);
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

    if (_period == 'Weekly') {
      final end = _selectedWeekStart.add(const Duration(days: 6));

      return '${_selectedWeekStart.day} '
          '${_shortMonth(_selectedWeekStart.month)} – '
          '${end.day} ${_shortMonth(end.month)}, ${end.year}';
    }

    if (_period == 'Yearly') {
      return '${_selectedMonth.year}';
    }

    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  void _changePeriodDate(int amount) {
    setState(() {
      if (_period == 'Weekly') {
        _selectedWeekStart = _selectedWeekStart.add(
          Duration(days: 7 * amount),
        );
      } else if (_period == 'Monthly') {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month + amount,
        );
      } else if (_period == 'Yearly') {
        _selectedMonth = DateTime(
          _selectedMonth.year + amount,
          _selectedMonth.month,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Charts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(color: gold),
              )
                  : RefreshIndicator(
                color: gold,
                onRefresh: _loadTransactions,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  children: [
                    _periodSelector(),
                    const SizedBox(height: 12),
                    _monthHeader(),
                    const SizedBox(height: 12),
                    _summaryCards(),
                    const SizedBox(height: 12),
                    _cashFlowCard(),
                    const SizedBox(height: 12),
                    _categoryBreakdown(),
                    const SizedBox(height: 12),
                    _topCategoriesCard(),
                  ],
                ),
              ),
            ),
          ],
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
              onTap: () {
                setState(() {
                  _period = period;

                  if (period == 'Weekly') {
                    _selectedWeekStart = _startOfWeek(DateTime.now());
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
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
        const Icon(
          Icons.calendar_month_rounded,
          size: 19,
          color: darkGold,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _monthLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkGold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _changePeriodDate(-1),
          icon: const Icon(Icons.chevron_left_rounded),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0EDE4),
          ),
        ),
        IconButton(
          onPressed: () => _changePeriodDate(1),
          icon: const Icon(Icons.chevron_right_rounded),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF0EDE4),
          ),
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
                        color: item.$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.$1,
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
                    _money(item.$2),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: item.$3,
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
    final groups = _chartGroups();
    double maxAmount = 1;

    for (final group in groups) {
      if (group.$2 > maxAmount) maxAmount = group.$2;
      if (group.$3 > maxAmount) maxAmount = group.$3;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Income vs Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              _legend(green, 'In'),
              const SizedBox(width: 8),
              _legend(red, 'Out'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: darkGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _period == 'Weekly'
                        ? 'Selected week'
                        : _period == 'Yearly'
                        ? 'Full year $_monthLabel overview'
                        : _monthLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    '+${_money(_income)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: green),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '-${_money(_expenses)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 125,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: groups.map((group) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _bar(group.$2 / maxAmount, green),
                            const SizedBox(width: 3),
                            _bar(group.$3 / maxAmount, red),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.$1,
                        style: const TextStyle(
                          fontSize: 11,
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

  List<(String, double, double)> _chartGroups() {
    if (_period == 'Yearly') {
      return List.generate(12, (i) {
        final month = DateTime(_selectedMonth.year, i + 1);

        return (
        _shortMonth(i + 1),
        _sumForMonth(month, true),
        _sumForMonth(month, false),
        );
      });
    }

    if (_period == 'Monthly') {
      final monthStart = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
      );

      final nextMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );

      return List.generate(4, (i) {
        final weekStart = monthStart.add(Duration(days: i * 7));
        final nextWeekStart = weekStart.add(const Duration(days: 7));

        final weekEnd =
        nextWeekStart.isBefore(nextMonth) ? nextWeekStart : nextMonth;

        final weekTransactions = _transactions.where((t) {
          return !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd);
        });

        final income = weekTransactions
            .where((t) => t.isIncome)
            .fold(0.0, (sum, t) => sum + t.amount);

        final expenses = weekTransactions
            .where((t) => !t.isIncome)
            .fold(0.0, (sum, t) => sum + t.amount);

        return ('W${i + 1}', income, expenses);
      });
    }

    return List.generate(7, (i) {
      final date = _selectedWeekStart.add(Duration(days: i));

      final dayTransactions = _filtered.where(
            (t) =>
        t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day,
      );

      return (
      ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
      dayTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount),
      dayTransactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount),
      );
    });
  }

  Widget _bar(double value, Color color) {
    return Flexible(
      child: Container(
        width: 10,
        height: (value * 82).clamp(3.0, 82.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(4),
          ),
        ),
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

    const colors = [
      Color(0xFF513829),
      Color(0xFFD9AA2B),
      Color(0xFFF3C95B),
      Color(0xFFB88600),
      Color(0xFF8D806D),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 18),
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
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _money(totalSpent),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: categories.take(5).toList().asMap().entries.map((e) {
              final percent =
              totalSpent == 0 ? 0.0 : e.value.value / totalSpent * 100;

              return SizedBox(
                width: 135,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[e.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${e.value.key} (${percent.toStringAsFixed(0)}%)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
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

    const colors = [
      Color(0xFF513829),
      Color(0xFFD9AA2B),
      Color(0xFFF3C95B),
      Color(0xFFB88600),
    ];

    const icons = [
      Icons.restaurant_rounded,
      Icons.shopping_bag_rounded,
      Icons.shopping_cart_rounded,
      Icons.directions_car_rounded,
    ];

    final totalSpent = _expenses;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Top Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${top.length} Categories',
                  style: const TextStyle(fontSize: 11, color: darkGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (top.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Add expenses to see your top categories.',
                  style: TextStyle(fontSize: 13, color: muted),
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

              final percent = totalSpent == 0
                  ? 0.0
                  : category.value / totalSpent * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F0DC),
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
                              fontSize: 11,
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          _money(category.value),
                          style: const TextStyle(
                            fontSize: 14,
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
                        '$count transactions • '
                            '${percent.toStringAsFixed(0)}% of total',
                        style: const TextStyle(
                          fontSize: 11,
                          color: muted,
                        ),
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

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      ],
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
    if (oldDelegate.values.length != values.length) return true;

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }

    return false;
  }
}