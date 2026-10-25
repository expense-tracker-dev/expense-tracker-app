import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color secondaryText = Color(0xFF514939);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E1D4);
  static const Color incomeColor = Color(0xFF6EAA91);
  static const Color expenseColor = Color(0xFFE98270);

  static const String _accountsStorageKey =
      'dailydhan_custom_accounts';

  static const double _accountSpacing = 12;

  static const List<IconData> _accountIcons = [
    Icons.payments_outlined,
    Icons.credit_card_rounded,
    Icons.chat_bubble_rounded,
    Icons.account_balance_outlined,
    Icons.savings_outlined,
    Icons.wallet_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.currency_exchange_rounded,
    Icons.storefront_outlined,
    Icons.work_outline_rounded,
    Icons.attach_money_rounded,
    Icons.account_box_outlined,
  ];

  final TransactionService _transactionService = TransactionService();

  List<TransactionModel> _transactions = [];
  List<Map<String, dynamic>> _customAccounts = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    TransactionService.transactionUpdates.addListener(
      _onTransactionsChanged,
    );

    _loadTransactions();
    _loadCustomAccounts();
  }

  @override
  void dispose() {
    TransactionService.transactionUpdates.removeListener(
      _onTransactionsChanged,
    );

    super.dispose();
  }

  void _onTransactionsChanged() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions =
      await _transactionService.getTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Unable to load transactions: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomAccounts() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final savedAccounts =
      preferences.getString(_accountsStorageKey);

      if (savedAccounts == null) return;

      final decoded = jsonDecode(savedAccounts) as List<dynamic>;

      final accounts = decoded
          .map(
            (item) => Map<String, dynamic>.from(item as Map),
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _customAccounts = accounts;
      });
    } catch (error) {
      debugPrint('Unable to load custom accounts: $error');
    }
  }

  Future<void> _persistCustomAccounts(
      List<Map<String, dynamic>> accounts,
      ) async {
    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _accountsStorageKey,
      jsonEncode(accounts),
    );

    if (!saved) {
      throw Exception('Unable to save accounts locally.');
    }
  }

  double _balanceFor(String accountType) {
    double balance = 0;

    for (final transaction in _transactions) {
      if ((transaction.accountId ?? '').toLowerCase() !=
          accountType) {
        continue;
      }

      balance += transaction.isIncome
          ? transaction.amount
          : -transaction.amount;
    }

    return balance;
  }

  double get _cardBalance => _balanceFor('card');

  double get _cashBalance => _balanceFor('cash');

  double get _savingsBalance => _balanceFor('savings');

  double get _customAccountsBalance {
    return _customAccounts.fold<double>(
      0,
          (total, account) =>
      total +
          ((account['initialAmount'] as num?)?.toDouble() ?? 0),
    );
  }

  double get _totalBalance =>
      _cardBalance +
          _cashBalance +
          _savingsBalance +
          _customAccountsBalance;

  String _formatAmount(double amount) {
    final value = amount.abs().toStringAsFixed(2).split('.');
    final integerPart = value[0];
    final decimalPart = value[1];

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      buffer.write(integerPart[i]);

      final remaining = integerPart.length - i - 1;

      if (remaining > 0 &&
          (remaining == 3 ||
              (remaining > 3 && (remaining - 3) % 2 == 0))) {
        buffer.write(',');
      }
    }

    return '${amount < 0 ? '-' : ''}'
        '${buffer.toString()}.$decimalPart';
  }

  String _formatRupees(double amount) {
    return '₹${_formatAmount(amount).replaceAll('.00', '')}';
  }

  Future<void> _showAddAccountDialog() async {
    HapticFeedback.selectionClick();

    final nameController = TextEditingController(text: 'Untitled');
    final amountController = TextEditingController(text: '0');

    int selectedIconIndex = 0;
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: cardColor,
                insetPadding:
                const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: dividerColor),
                ),
                child: SizedBox(
                  width: 300,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      14,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Add new account',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                flex: 5,
                                child: Text(
                                  'Initial amount',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: TextField(
                                  controller: amountController,
                                  keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  onTap: () {
                                    if (amountController.text == '0') {
                                      amountController.selection =
                                          TextSelection(
                                            baseOffset: 0,
                                            extentOffset:
                                            amountController.text.length,
                                          );
                                    }
                                  },
                                  style: const TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: background,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: dividerColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: gold,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '*Initial amount is separate from transaction analysis',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                flex: 4,
                                child: Text(
                                  'Name',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: TextField(
                                  controller: nameController,
                                  textCapitalization:
                                  TextCapitalization.words,
                                  style: const TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: background,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: dividerColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: gold,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Icon',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 78,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: dividerColor),
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _accountIcons.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final selected =
                                    selectedIconIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedIconIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 150,
                                    ),
                                    width: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? gold
                                            : dividerColor,
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _accountIcons[index],
                                      size: 27,
                                      color:
                                      selected ? darkGold : muted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: dividerColor),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () {
                                    Navigator.pop(dialogContext);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: textColor,
                                    side: const BorderSide(
                                      color: dividerColor,
                                    ),
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                    final name =
                                    nameController.text.trim();

                                    final amount = double.tryParse(
                                      amountController.text,
                                    );

                                    if (name.isEmpty ||
                                        amount == null ||
                                        !amount.isFinite ||
                                        amount < 0) {
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Enter a valid account name and amount.',
                                          ),
                                          backgroundColor: darkGold,
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isSaving = true;
                                    });

                                    final newAccount =
                                    <String, dynamic>{
                                      'id': DateTime.now()
                                          .microsecondsSinceEpoch
                                          .toString(),
                                      'name': name,
                                      'initialAmount': amount,
                                      'iconIndex': selectedIconIndex,
                                      'createdAt': DateTime.now()
                                          .toIso8601String(),
                                    };

                                    final updatedAccounts = [
                                      ..._customAccounts,
                                      newAccount,
                                    ];

                                    try {
                                      await _persistCustomAccounts(
                                        updatedAccounts,
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        _customAccounts =
                                            updatedAccounts;
                                      });

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }

                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$name account added successfully.',
                                          ),
                                          backgroundColor: darkGold,
                                        ),
                                      );
                                    } catch (error) {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          isSaving = false;
                                        });
                                      }

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not save account: $error',
                                          ),
                                          backgroundColor: expenseColor,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: gold,
                                    foregroundColor: darkGold,
                                    disabledBackgroundColor:
                                    gold.withValues(alpha: 0.5),
                                    elevation: 0,
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: darkGold,
                                    ),
                                  )
                                      : const Text(
                                    'SAVE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _deleteCustomAccount(
      Map<String, dynamic> account,
      ) async {
    final name = account['name'] as String? ?? 'Account';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Delete account?',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Remove "$name" from your accounts?',
            style: const TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'DELETE',
                style: TextStyle(color: expenseColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final updatedAccounts = _customAccounts
        .where((item) => item['id'] != account['id'])
        .toList();

    try {
      await _persistCustomAccounts(updatedAccounts);

      if (!mounted) return;

      setState(() {
        _customAccounts = updatedAccounts;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name account deleted.'),
          backgroundColor: darkGold,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete account: $error'),
          backgroundColor: expenseColor,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MONEY SOURCES',
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Accounts',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Manage your money sources',
          style: TextStyle(
            color: muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5526).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL NET BALANCE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDBF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: incomeColor,
                      size: 7,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'All Active',
                      style: TextStyle(
                        color: darkGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isLoading ? '₹0' : _formatRupees(_totalBalance),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '.00',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: dividerColor, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBalanceColumn('CARD', _cardBalance),
              _buildVerticalDivider(),
              _buildBalanceColumn('CASH', _cashBalance),
              _buildVerticalDivider(),
              _buildBalanceColumn('SAVINGS', _savingsBalance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceColumn(String label, double amount) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _isLoading ? '₹0' : _formatRupees(amount),
              style: const TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: dividerColor,
    );
  }

  Widget _buildAccountSection({
    required String title,
    required String subtitle,
    required double balance,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5526).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9B4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: darkGold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: background,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () {
                HapticFeedback.selectionClick();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$title transactions will appear here.',
                    ),
                    backgroundColor: darkGold,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? '₹0' : _formatRupees(balance),
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAccountSection(
      Map<String, dynamic> account,
      ) {
    final name = account['name'] as String? ?? 'Untitled';

    final initialAmount =
        (account['initialAmount'] as num?)?.toDouble() ?? 0;

    final iconIndex =
        (account['iconIndex'] as num?)?.toInt() ?? 0;

    final safeIconIndex =
    iconIndex >= 0 && iconIndex < _accountIcons.length
        ? iconIndex
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5526).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9B4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _accountIcons[safeIconIndex],
                  color: darkGold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Custom account',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 35,
                height: 35,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete account',
                  onPressed: () => _deleteCustomAccount(account),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: muted,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: background,
            borderRadius: BorderRadius.circular(13),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Balance',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRupees(initialAmount),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showAddAccountDialog,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFD7C5A1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                  color: gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: darkGold,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Account',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add a Card, Cash, or Savings source',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: darkGold,
          backgroundColor: cardColor,
          onRefresh: () async {
            await Future.wait([
              _loadTransactions(),
              _loadCustomAccounts(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildBalanceCard(),
              const SizedBox(height: 14),

              _buildAccountSection(
                title: 'Card',
                subtitle: 'Balance',
                balance: _cardBalance,
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: _accountSpacing),

              _buildAccountSection(
                title: 'Cash',
                subtitle: 'Balance',
                balance: _cashBalance,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: _accountSpacing),

              _buildAccountSection(
                title: 'Savings',
                subtitle: 'Balance',
                balance: _savingsBalance,
                icon: Icons.account_balance_outlined,
              ),

              if (_customAccounts.isNotEmpty) ...[
                const SizedBox(height: _accountSpacing),
                ..._customAccounts.map(
                      (account) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: _accountSpacing,
                    ),
                    child: _buildCustomAccountSection(account),
                  ),
                ),
              ],

              const SizedBox(height: 3),
              _buildAddAccountButton(),
              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'DAILYDHAN',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 5),

              const Center(
                child: Text(
                  'Your money, organised in one place.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}