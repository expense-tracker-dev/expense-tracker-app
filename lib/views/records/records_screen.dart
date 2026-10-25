import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../transactions/add_transaction_screen.dart';
import 'dashboard_screen.dart';
import '../categories/categories_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color secondaryText = Color(0xFF514939);
  static const Color iconColor = Color(0xFF887D67);
  static const Color cardColor = Colors.white;

  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  List<CategoryItem> _categories = [];
  Map<String, String> _accountNames = {};

  bool _isLoading = true;

  double get _totalIncome => _transactions
      .where((transaction) => transaction.isIncome)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  double get _totalExpense => _transactions
      .where((transaction) => !transaction.isIncome)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  double get _totalBalance => _totalIncome - _totalExpense;

  @override
  void initState() {
    super.initState();
    TransactionService.transactionUpdates.addListener(
      _onTransactionsUpdated,
    );
    _loadData();
  }

  @override
  void dispose() {
    TransactionService.transactionUpdates.removeListener(
      _onTransactionsUpdated,
    );
    super.dispose();
  }

  void _onTransactionsUpdated() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _transactionService.getTransactions(),
        CategoryService().getCategories(),
        _loadAccountNames(),
      ]);

      if (!mounted) return;

      setState(() {
        _transactions = results[0] as List<TransactionModel>;
        _categories = results[1] as List<CategoryItem>;
        _accountNames = results[2] as Map<String, String>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> _loadAccountNames() async {
    final Map<String, String> names = {
      'card': 'Card',
      'cash': 'Cash',
      'savings': 'Savings',
    };

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('dailydhan_custom_accounts');

    if (stored != null) {
      final List<dynamic> accounts = jsonDecode(stored) as List<dynamic>;

      for (final item in accounts) {
        final account = Map<String, dynamic>.from(item as Map);
        final id = account['id']?.toString();
        final name = account['name']?.toString();

        if (id != null && name != null) {
          names[id] = name;
        }
      }
    }

    return names;
  }

  String _formatAmount(double amount) {
    return '₹${amount.abs().toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    String dateLabel;

    if (transactionDay == today) {
      dateLabel = 'Today';
    } else if (transactionDay == today.subtract(
      const Duration(days: 1),
    )) {
      dateLabel = 'Yesterday';
    } else {
      const months = [
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
      dateLabel = '${date.day} ${months[date.month - 1]}';
    }

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dateLabel • $hour:$minute $period';
  }

  CategoryItem? _getCategory(String name) {
    for (final category in _categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) {
        return category;
      }
    }
    return null;
  }

  Future<void> _openAddTransaction(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: type),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Menu',
                barrierColor: Colors.black54,
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: background,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.82,
                        height: double.infinity,
                        child: DashboardScreen(
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  );
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              );
            },
            icon: const Icon(Icons.menu_rounded),
            color: textColor,
          ),
          const SizedBox(width: 8),
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFD9AA2B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'DailyDhan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE6BD53),
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
          const Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF795900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalBalance < 0 ? '-' : ''}${_formatAmount(_totalBalance)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF211F19),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _balanceInfo(
                  Icons.arrow_downward_rounded,
                  'Income',
                  _formatAmount(_totalIncome),
                  const Color(0xFF326C4D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _balanceInfo(
                  Icons.arrow_upward_rounded,
                  'Expenses',
                  _formatAmount(_totalExpense),
                  const Color(0xFF963F32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceInfo(
      IconData icon,
      String title,
      String amount,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF514939),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.add_rounded,
                label: 'Add Income',
                color: const Color(0xFF39835F),
                onTap: () => _openAddTransaction('Income'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildQuickAction(
                icon: Icons.remove_rounded,
                label: 'Add Expense',
                color: const Color(0xFFD3654F),
                onTap: () => _openAddTransaction('Expense'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 17,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFF0E8D8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _openAllTransactions,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: darkGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF0E8D8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: gold),
            ),
          )
              : _transactions.isEmpty
              ? _buildEmptyTransactions()
              : Column(
            children: _transactions.take(5).map((transaction) {
              return _buildTransactionTile(transaction);
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openAllTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            iconTheme: const IconThemeData(color: textColor),
            title: const Text(
              'All Transactions',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
                : _transactions.isEmpty
                ? Center(
              child: _buildEmptyTransactions(),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF0E8D8),
                    ),
                  ),
                  child: _buildTransactionTile(
                    _transactions[index],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return const SizedBox(
      height: 280,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: Color(0xFFC8BDA7),
          ),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Your income and expenses will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final category = _getCategory(transaction.category);
    final isIncome = transaction.isIncome;
    final categoryColor = category?.color ??
        (isIncome
            ? const Color(0xFF4F9B76)
            : const Color(0xFFD8785F));
    final categoryIcon = category?.icon ??
        (isIncome
            ? Icons.account_balance_wallet_rounded
            : Icons.receipt_long);
    final accountName = _accountNames[transaction.accountId] ?? 'Account';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              categoryIcon,
              color: categoryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(transaction.date)} • $accountName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+' : '-'}${_formatAmount(transaction.amount)}',
            style: TextStyle(
              color: isIncome
                  ? const Color(0xFF39835F)
                  : const Color(0xFFD3654F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF0E8D8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.receipt_long_rounded, 'Records', true),
            _buildNavItem(Icons.bar_chart_rounded, 'Charts', false),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            _buildNavItem(
              Icons.pie_chart_outline_rounded,
              'Budgets',
              false,
            ),
            _buildNavItem(
              Icons.account_balance_wallet_outlined,
              'Accounts',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon,
      String label,
      bool selected,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: selected ? darkGold : iconColor,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: selected ? darkGold : iconColor,
            fontSize: 10,
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 26),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}