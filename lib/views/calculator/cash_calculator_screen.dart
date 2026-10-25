
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CashCalculatorScreen extends StatefulWidget {
  const CashCalculatorScreen({super.key});

  @override
  State<CashCalculatorScreen> createState() =>
      _CashCalculatorScreenState();
}

class _CashCalculatorScreenState extends State<CashCalculatorScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E1D4);

  static const String historyStorageKey = 'cash_calculator_history';

  final List<int> denominations = [500, 200, 100, 50, 20, 10];

  final Map<int, int> noteCounts = {
    500: 0,
    200: 0,
    100: 0,
    50: 0,
    20: 0,
    10: 0,
  };

  final Map<int, int> coinCounts = {
    1: 0,
    2: 0,
    5: 0,
    10: 0,
  };

  final List<Map<String, dynamic>> calculationHistory = [];

  bool showCoins = false;
  bool _historyLoading = true;
  bool _savingRecord = false;

  final NumberFormat currencyFormat =
  NumberFormat('#,##,##0.##', 'en_IN');

  final DateFormat dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  double get totalCash {
    double total = 0;

    for (final denomination in denominations) {
      total += denomination * (noteCounts[denomination] ?? 0);
    }

    for (final denomination in coinCounts.keys) {
      total += denomination * (coinCounts[denomination] ?? 0);
    }

    return total;
  }

  int get totalPieces {
    int pieces = 0;

    for (final count in noteCounts.values) {
      pieces += count;
    }

    for (final count in coinCounts.values) {
      pieces += count;
    }

    return pieces;
  }

  String money(double amount) {
    return '₹${currencyFormat.format(amount)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHistory = prefs.getString(historyStorageKey);

      if (savedHistory != null && savedHistory.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedHistory);

        final loadedHistory = decoded.map((item) {
          final entry = Map<String, dynamic>.from(item as Map);

          return <String, dynamic>{
            'amount': (entry['amount'] as num).toDouble(),
            'date': DateTime.parse(entry['date'] as String),
            'pieces': (entry['pieces'] as num).toInt(),
          };
        }).toList();

        if (mounted) {
          setState(() {
            calculationHistory
              ..clear()
              ..addAll(loadedHistory);
          });
        }
      }
    } catch (_) {
      _showMessage('Unable to load saved calculation history.');
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedHistory = calculationHistory.map((item) {
      return <String, dynamic>{
        'amount': item['amount'],
        'date': (item['date'] as DateTime).toIso8601String(),
        'pieces': item['pieces'],
      };
    }).toList();

    final success = await prefs.setString(
      historyStorageKey,
      jsonEncode(encodedHistory),
    );

    if (!success) {
      throw Exception('History could not be saved.');
    }
  }

  void updateNoteCount(int denomination, int change) {
    setState(() {
      final current = noteCounts[denomination] ?? 0;
      noteCounts[denomination] =
          (current + change).clamp(0, 999999);
    });
  }

  void updateCoinCount(int denomination, int change) {
    setState(() {
      final current = coinCounts[denomination] ?? 0;
      coinCounts[denomination] =
          (current + change).clamp(0, 999999);
    });
  }

  void resetCalculation() {
    setState(() {
      for (final denomination in denominations) {
        noteCounts[denomination] = 0;
      }

      for (final denomination in coinCounts.keys.toList()) {
        coinCounts[denomination] = 0;
      }

      showCoins = false;
    });
  }

  Future<void> saveRecord() async {
    if (_historyLoading) {
      _showMessage('Please wait while history loads.');
      return;
    }

    if (_savingRecord) return;

    if (totalCash <= 0) {
      _showMessage('Count cash before saving the record.');
      return;
    }

    final entry = <String, dynamic>{
      'amount': totalCash,
      'date': DateTime.now(),
      'pieces': totalPieces,
    };

    setState(() {
      _savingRecord = true;
      calculationHistory.insert(0, entry);
    });

    try {
      await _persistHistory();

      if (!mounted) return;

      _showMessage('Cash record saved successfully.');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        calculationHistory.remove(entry);
      });

      _showMessage('Could not save the cash record.');
    } finally {
      if (mounted) {
        setState(() {
          _savingRecord = false;
        });
      }
    }
  }

  void showHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.70,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Calculation History',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: dividerColor),
                Expanded(
                  child: _historyLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: gold,
                    ),
                  )
                      : calculationHistory.isEmpty
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 46,
                            color: muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No calculation history yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Count cash and tap Save Record '
                                'to save your first total.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: calculationHistory.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = calculationHistory[index];
                      final date = item['date'] as DateTime;
                      final amount = item['amount'] as double;
                      final pieces = item['pieces'] as int;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                          BorderRadius.circular(15),
                          border: Border.all(
                            color: dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: gold.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: darkGold,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    money(amount),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFormat.format(date)}'
                                        ' • ${timeFormat.format(date)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$pieces pieces',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String buildSlipText() {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('DAILYDHAN - CASH CALCULATOR');
    buffer.writeln('--------------------------------');
    buffer.writeln('Date: ${dateFormat.format(now)}');
    buffer.writeln('Time: ${timeFormat.format(now)}');
    buffer.writeln();
    buffer.writeln('PHYSICAL NOTES TALLY');

    for (final denomination in denominations) {
      final count = noteCounts[denomination] ?? 0;

      buffer.writeln(
        '₹$denomination x $count = '
            '${money(denomination * count.toDouble())}',
      );
    }

    buffer.writeln();
    buffer.writeln('COINS & LOOSE CHANGE');

    for (final denomination in coinCounts.keys) {
      final count = coinCounts[denomination] ?? 0;

      buffer.writeln(
        '₹$denomination x $count = '
            '${money(denomination * count.toDouble())}',
      );
    }

    buffer.writeln();
    buffer.writeln('Total pieces: $totalPieces');
    buffer.writeln('TOTAL CASH COUNTED: ${money(totalCash)}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Generated using DailyDhan');

    return buffer.toString();
  }

  Future<void> shareSlip() async {
    if (totalCash <= 0) {
      _showMessage('Count cash before sharing the slip.');
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buildSlipText(),
          subject: 'DailyDhan Cash Count Slip',
        ),
      );
    } catch (_) {
      _showMessage('Unable to share the cash slip.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),
        title: const Text(
          'Cash Calculator',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNoteTallyButton(),
              const SizedBox(height: 18),
              _buildTotalCard(),
              const SizedBox(height: 22),
              _buildSectionHeader(),
              const SizedBox(height: 12),
              ...denominations.map(
                    (denomination) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDenominationRow(denomination),
                ),
              ),
              const SizedBox(height: 4),
              _buildCoinsCard(),
              const SizedBox(height: 16),
              _buildVerifiedCard(),
              const SizedBox(height: 18),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTallyButton() {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: dividerColor),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payments_outlined,
            size: 20,
            color: darkGold,
          ),
          SizedBox(width: 8),
          Text(
            'Note Tally',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dividerColor.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.circle, size: 9, color: darkGold),
              SizedBox(width: 8),
              Text(
                'TOTAL CASH COUNTED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            money(totalCash),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: resetCalculation,
                    icon: const Icon(
                      Icons.restart_alt_rounded,
                      size: 19,
                    ),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0EBDD),
                      foregroundColor: textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: showHistory,
                    icon: const Icon(
                      Icons.history_rounded,
                      size: 19,
                    ),
                    label: const Text('History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PHYSICAL NOTES TALLY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Text(
            'Descending Currency Order',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationRow(int denomination) {
    final count = noteCounts[denomination] ?? 0;
    final amount = denomination * count;

    final Color noteColor;
    final Color noteBackground;

    switch (denomination) {
      case 500:
        noteColor = const Color(0xFF6C7767);
        noteBackground = const Color(0xFFE1E7DC);
        break;
      case 200:
        noteColor = const Color(0xFFB46B36);
        noteBackground = const Color(0xFFFFE5D1);
        break;
      case 100:
        noteColor = const Color(0xFF7779A9);
        noteBackground = const Color(0xFFE5E5F7);
        break;
      case 50:
        noteColor = const Color(0xFF4C8C91);
        noteBackground = const Color(0xFFDFF1F0);
        break;
      case 20:
        noteColor = const Color(0xFF8C9954);
        noteBackground = const Color(0xFFEDF1D9);
        break;
      default:
        noteColor = const Color(0xFF9B7665);
        noteBackground = const Color(0xFFF0DED3);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 46,
            decoration: BoxDecoration(
              color: noteBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 5,
                  top: 4,
                  child: Text(
                    '₹$denomination',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: noteColor,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 18,
                    color: noteColor,
                  ),
                ),
                const Positioned(
                  left: 5,
                  bottom: 4,
                  child: Text(
                    'RBI',
                    style: TextStyle(
                      fontSize: 6,
                      color: muted,
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Text(
                    'SPECIMEN',
                    style: TextStyle(
                      fontSize: 5,
                      color: noteColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '₹$denomination',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '× $count',
                        style: const TextStyle(
                          fontSize: 13,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  money(amount.toDouble()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkGold,
                  ),
                ),
              ],
            ),
          ),
          _buildCounter(
            count: count,
            onDecrease: () => updateNoteCount(denomination, -1),
            onIncrease: () => updateNoteCount(denomination, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter({
    required int count,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: dividerColor, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _counterButton(
            icon: Icons.remove_rounded,
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
          _counterButton(
            icon: Icons.add_rounded,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 38,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: 19,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCoinsCard() {
    final coinTotal = coinCounts.entries.fold<int>(
      0,
          (sum, entry) => sum + (entry.key * entry.value),
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                showCoins = !showCoins;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.toll_outlined,
                      color: darkGold,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coins & Loose Change',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aggregate for ₹1, ₹2, ₹5 & ₹10',
                          style: TextStyle(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    money(coinTotal.toDouble()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkGold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    showCoins
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 23,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          if (showCoins) ...[
            const Divider(height: 1, color: dividerColor),
            ...coinCounts.keys.map(
                  (denomination) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '₹$denomination coins',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    _buildCounter(
                      count: coinCounts[denomination] ?? 0,
                      onDecrease: () =>
                          updateCoinCount(denomination, -1),
                      onIncrease: () =>
                          updateCoinCount(denomination, 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBDD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: muted,
            size: 21,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Physical Cash Verified',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            '$totalPieces pcs • ${money(totalCash)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: shareSlip,
              icon: const Icon(
                Icons.share_outlined,
                size: 19,
              ),
              label: const Text('Share Slip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: darkGold,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: dividerColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _savingRecord ? null : saveRecord,
              icon: _savingRecord
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
                  : const Icon(
                Icons.save_outlined,
                size: 19,
              ),
              label: Text(
                _savingRecord ? 'Saving...' : 'Save Record',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: textColor,
                disabledBackgroundColor: gold.withValues(alpha: 0.6),
                disabledForegroundColor: textColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
