import 'package:flutter/material.dart';
import '../../services/forecast_service.dart';

class MoneyForecastScreen extends StatefulWidget {
  const MoneyForecastScreen({super.key});

  @override
  State<MoneyForecastScreen> createState() =>
      _MoneyForecastScreenState();
}

class _MoneyForecastScreenState extends State<MoneyForecastScreen> {
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color background = Color(0xFFFCF8EF);
  static const Color cardColor = Color(0xFFFFFDF8);
  static const Color dividerColor = Color(0xFFE8E1D4);
  static const Color expenseColor = Color(0xFFE98270);
  static const Color incomeColor = Color(0xFF579777);

  final ForecastService _forecastService = ForecastService();

  Map<String, dynamic>? dailyPrediction;
  Map<String, dynamic>? monthlyPrediction;

  bool isLoading = true;
  String? errorMessage;

  String selectedPeriod = 'Monthly Prediction';

  final List<String> periods = [
    'Daily Prediction',
    'Monthly Prediction',
  ];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _forecastService.getDailyPrediction(),
        _forecastService.getMonthlyPrediction(),
      ]);

      if (!mounted) return;

      setState(() {
        dailyPrediction = results[0];
        monthlyPrediction = results[1];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _forecastService.dispose();
    super.dispose();
  }

  double? _amount(Map<String, dynamic>? data, String key) {
    final value = data?[key];

    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return null;
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '--';

    final value = amount.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i > 0 &&
          (value.length - i) > 3 &&
          (value.length - i - 3) % 2 == 0) {
        result.write(',');
      }
      result.write(value[i]);
    }

    return '₹ $result';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),
        title: const Text(
          'Money Forecast',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: darkGold,
          onRefresh: _loadForecast,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _buildIntro(),
              const SizedBox(height: 22),
              _buildPeriodSelector(),
              const SizedBox(height: 18),
              if (isLoading)
                _buildLoading()
              else if (errorMessage != null)
                _buildError()
              else ...[
                  if (selectedPeriod == 'Daily Prediction')
                    _buildDailyCard()
                  else
                    _buildMonthlyCard(),
                  const SizedBox(height: 18),
                  _buildSummaryCards(),
                  const SizedBox(height: 22),
                  _buildInsightCard(),
                ],
              const SizedBox(height: 22),
              _buildDisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan ahead with confidence',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Get expense predictions from the DailyDhan forecasting service.',
          style: TextStyle(
            color: muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Prediction type',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: cardColor,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: darkGold,
              ),
              style: const TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              items: periods.map((period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: darkGold),
          SizedBox(height: 18),
          Text(
            'Getting your predictions...',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Connecting to the ML forecasting service.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: expenseColor,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load predictions',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadForecast,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: textColor,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard() {
    final amount = _amount(
      dailyPrediction,
      'predicted_expense',
    );

    final date = _formatDate(dailyPrediction?['date']);

    return _buildMainCard(
      title: "Tomorrow's predicted expense",
      amount: _formatAmount(amount),
      subtitle: date,
      icon: Icons.auto_graph_rounded,
    );
  }

  Widget _buildMonthlyCard() {
    final amount = _amount(
      monthlyPrediction,
      'estimated_month_end_expense',
    );

    final month = monthlyPrediction?['current_month']?.toString() ??
        'Current month';

    return _buildMainCard(
      title: 'Estimated month-end expense',
      amount: _formatAmount(amount),
      subtitle: month,
      icon: Icons.calendar_month_rounded,
    );
  }

  Widget _buildMainCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8C45D),
            Color(0xFFD9AA2B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: darkGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: darkGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.insights_rounded,
                color: darkGold,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: const TextStyle(
                color: textColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: Color(0xFF315F43),
                ),
                SizedBox(width: 5),
                Text(
                  'ML API prediction',
                  style: TextStyle(
                    color: Color(0xFF315F43),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0x66FFFFFF)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: darkGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: darkGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final dailyAmount = _amount(
      dailyPrediction,
      'predicted_expense',
    );

    final nextMonthAmount = _amount(
      monthlyPrediction,
      'predicted_next_month_expense',
    );

    final nextMonth = monthlyPrediction?['next_month']?.toString() ??
        'Next month';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: "Tomorrow's Expense",
            amount: _formatAmount(dailyAmount),
            icon: Icons.north_east_rounded,
            color: expenseColor,
            backgroundColor: const Color(0xFFFFEFEB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Next Month',
            subtitle: nextMonth,
            amount: _formatAmount(nextMonthAmount),
            icon: Icons.calendar_month_rounded,
            color: darkGold,
            backgroundColor: const Color(0xFFFFF3D2),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    String? subtitle,
    required String amount,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: const TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    final month = monthlyPrediction?['current_month']?.toString() ??
        'the current month';

    final nextMonth = monthlyPrediction?['next_month']?.toString() ??
        'next month';

    final currentAmount = _amount(
      monthlyPrediction,
      'estimated_month_end_expense',
    );

    final nextAmount = _amount(
      monthlyPrediction,
      'predicted_next_month_expense',
    );

    String insight;

    if (currentAmount == null || nextAmount == null) {
      insight = 'Monthly insights will appear when prediction data is available.';
    } else if (nextAmount > currentAmount) {
      insight =
      'The predicted expense for $nextMonth is higher than the estimated '
          'month-end expense for $month.';
    } else if (nextAmount < currentAmount) {
      insight =
      'The predicted expense for $nextMonth is lower than the estimated '
          'month-end expense for $month.';
    } else {
      insight =
      'The predicted expense for $nextMonth is equal to the estimated '
          'month-end expense for $month.';
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEDDAF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: darkGold,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Money Insight',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  insight,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: muted,
          size: 17,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Predictions are estimates, not guarantees. The current ML model '
                'uses its training history, not your personal DailyDhan records.',
            style: TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}