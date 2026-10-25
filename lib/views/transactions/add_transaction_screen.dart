import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../categories/categories_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;

  const AddTransactionScreen({
    super.key,
    this.initialType = 'Income',
  });

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color cardColor = Color(0xFFFFFDF7);
  static const Color incomeColor = Color(0xFF6EAA91);
  static const Color expenseColor = Color(0xFFE98270);
  static const Color dividerColor = Color(0xFFE8E1D4);

  static const String _accountsStorageKey =
      'dailydhan_custom_accounts';

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
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _noteController = TextEditingController();

  List<CategoryItem> _allCategories = [];
  List<Map<String, dynamic>> _customAccounts = [];

  bool _categoriesLoading = true;
  bool _accountsLoading = false;

  String _type = 'Income';
  String _amount = '0';
  String _category = 'Salary';

  String? _accountId;
  String _accountName = 'Select Account';

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  double? _storedValue;
  String? _pendingOperator;
  bool _startNewNumber = false;

  List<CategoryItem> get _categories => _allCategories
      .where((category) => category.isIncome == (_type == 'Income'))
      .toList();

  double get _amountValue => double.tryParse(_amount) ?? 0;

  Color get _activeColor =>
      _type == 'Income' ? incomeColor : expenseColor;

  String get _formattedAmount {
    final parts = _amountValue.toStringAsFixed(2).split('.');
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

    return '${buffer.toString()}.${parts[1]}';
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadCategories();
    _loadCustomAccounts();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomAccounts() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_accountsStorageKey);

      final List<Map<String, dynamic>> accounts = saved == null
          ? []
          : (jsonDecode(saved) as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) return;

      setState(() {
        _customAccounts = accounts;

        if (_accountId != null &&
            !_isBuiltInAccount(_accountId!) &&
            !_customAccounts.any(
                  (account) => account['id'].toString() == _accountId,
            )) {
          _accountId = null;
          _accountName = 'Select Account';
        }
      });
    } catch (error) {
      debugPrint('Unable to load accounts: $error');

      if (!mounted) return;

      _showMessage('Unable to load custom accounts.');
    }
  }

  bool _isBuiltInAccount(String id) {
    return ['card', 'cash', 'savings'].contains(id);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();

      if (!mounted) return;

      setState(() {
        _allCategories = categories;
        _categoriesLoading = false;

        final matchingCategories = categories
            .where((category) => category.isIncome == (_type == 'Income'))
            .toList();

        if (!matchingCategories.any(
              (category) => category.name == _category,
        )) {
          _category = matchingCategories.isNotEmpty
              ? matchingCategories.first.name
              : '';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _categoriesLoading = false;
      });

      _showMessage('Unable to load categories.');
    }
  }

  Future<void> _manageCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoriesScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _categoriesLoading = true;
    });

    await _loadCategories();
  }

  void _changeType(String type) {
    if (type == 'Transfer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer will be available later.'),
          backgroundColor: darkGold,
        ),
      );
      return;
    }

    setState(() {
      _type = type;

      final matchingCategories = _allCategories
          .where((category) => category.isIncome == (type == 'Income'))
          .toList();

      _category = matchingCategories.isNotEmpty
          ? matchingCategories.first.name
          : '';

      _storedValue = null;
      _pendingOperator = null;
      _startNewNumber = false;
    });
  }

  String _cleanNumber(double value) {
    if (!value.isFinite) return '0';

    final rounded = double.parse(value.toStringAsFixed(2));

    if (rounded == rounded.truncateToDouble()) {
      return rounded.toInt().toString();
    }

    return rounded.toString();
  }

  double? _calculate(
      double first,
      double second,
      String operator,
      ) {
    double result;

    switch (operator) {
      case '+':
        result = first + second;
        break;
      case '−':
        result = first - second;
        break;
      case '×':
        result = first * second;
        break;
      case '÷':
        if (second == 0) return null;
        result = first / second;
        break;
      default:
        return second;
    }

    if (!result.isFinite) return null;

    return double.parse(result.toStringAsFixed(2));
  }

  void _pressKey(String key) {
    if (_saving) return;

    HapticFeedback.selectionClick();

    setState(() {
      if (key == '⌫') {
        if (_startNewNumber) {
          _storedValue = null;
          _pendingOperator = null;
          _startNewNumber = false;
        }

        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);

          if (_amount == '-' || _amount.isEmpty) {
            _amount = '0';
          }
        } else {
          _amount = '0';
        }

        return;
      }

      if (key == '.') {
        if (_startNewNumber) {
          _amount = '0.';
          _startNewNumber = false;
          return;
        }

        if (!_amount.contains('.')) {
          _amount = '$_amount.';
        }

        return;
      }

      if (['+', '−', '×', '÷'].contains(key)) {
        if (_pendingOperator != null &&
            _storedValue != null &&
            !_startNewNumber) {
          final result = _calculate(
            _storedValue!,
            _amountValue,
            _pendingOperator!,
          );

          if (result == null) {
            _showMessage('Cannot divide by zero.');
            _pendingOperator = null;
            _storedValue = null;
            return;
          }

          _amount = _cleanNumber(result);
          _storedValue = result;
        } else {
          _storedValue = _amountValue;
        }

        _pendingOperator = key;
        _startNewNumber = true;
        return;
      }

      if (!RegExp(r'^[0-9]$').hasMatch(key)) return;

      if (_startNewNumber) {
        _amount = key;
        _startNewNumber = false;
        return;
      }

      if (_amount == '0') {
        _amount = key;
        return;
      }

      final decimalIndex = _amount.indexOf('.');

      if (decimalIndex != -1 &&
          _amount.length - decimalIndex > 2) {
        return;
      }

      if (_amount.length < 12) {
        _amount += key;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: darkGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectAccount() async {
    setState(() {
      _accountsLoading = true;
    });

    await _loadCustomAccounts();

    if (!mounted) return;

    setState(() {
      _accountsLoading = false;
    });

    final accounts = <Map<String, dynamic>>[
      {
        'id': 'card',
        'name': 'Card',
        'subtitle': 'Card balance',
        'icon': Icons.credit_card_rounded,
      },
      {
        'id': 'cash',
        'name': 'Cash',
        'subtitle': 'Cash balance',
        'icon': Icons.payments_outlined,
      },
      {
        'id': 'savings',
        'name': 'Savings',
        'subtitle': 'Savings balance',
        'icon': Icons.account_balance_outlined,
      },
      ..._customAccounts.map((account) {
        final iconIndex =
            (account['iconIndex'] as num?)?.toInt() ?? 0;

        final safeIconIndex =
        iconIndex >= 0 && iconIndex < _accountIcons.length
            ? iconIndex
            : 0;

        return <String, dynamic>{
          'id': account['id'].toString(),
          'name': account['name']?.toString() ?? 'Untitled',
          'subtitle': 'Custom account',
          'icon': _accountIcons[safeIconIndex],
        };
      }),
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Account',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose where to record this transaction.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final id = account['id'] as String;
                      final selected = _accountId == id;

                      return Material(
                        color: selected
                            ? const Color(0xFFFFF3D4)
                            : background,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () {
                            setState(() {
                              _accountId = id;
                              _accountName = account['name'] as String;
                            });

                            Navigator.pop(sheetContext);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE9B4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    account['icon'] as IconData,
                                    color: darkGold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account['name'] as String,
                                        style: const TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        account['subtitle'] as String,
                                        style: const TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.chevron_right_rounded,
                                  color: selected ? darkGold : muted,
                                ),
                              ],
                            ),
                          ),
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: gold,
              onPrimary: textColor,
              surface: cardColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: gold,
              onPrimary: textColor,
              surface: cardColor,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _selectedDate.hour,
        time?.minute ?? _selectedDate.minute,
      );
    });
  }

  Future<void> _viewAllCategories() async {
    final categories = _categories;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...categories.map((category) {
                  final selected = category.name == _category;

                  return ChoiceChip(
                    avatar: Icon(
                      category.icon,
                      size: 17,
                      color: selected ? darkGold : category.color,
                    ),
                    label: Text(category.name),
                    selected: selected,
                    selectedColor: const Color(0xFFFFE9B4),
                    backgroundColor: background,
                    labelStyle: TextStyle(
                      color: selected ? darkGold : textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _category = category.name;
                      });
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                ActionChip(
                  avatar: const Icon(
                    Icons.settings_outlined,
                    color: darkGold,
                    size: 17,
                  ),
                  label: const Text('Manage Categories'),
                  backgroundColor: const Color(0xFFFFE9B4),
                  labelStyle: const TextStyle(
                    color: darkGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _manageCategories();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTransaction() async {
    if (_saving) return;

    double finalAmount = _amountValue;

    if (_pendingOperator != null &&
        _storedValue != null &&
        !_startNewNumber) {
      final result = _calculate(
        _storedValue!,
        _amountValue,
        _pendingOperator!,
      );

      if (result == null) {
        _showMessage('Cannot divide by zero.');
        return;
      }

      finalAmount = result;
    }

    if (finalAmount <= 0) {
      _showMessage('Please enter an amount greater than zero.');
      return;
    }

    if (_categories.isEmpty) {
      _showMessage('Please add a category before saving.');
      return;
    }

    if (!_categories.any((category) => category.name == _category)) {
      _showMessage('Please select a valid category.');
      return;
    }

    if (_accountId == null) {
      _showMessage('Please select an account.');
      await _selectAccount();

      if (_accountId == null || !mounted) return;
    }

    setState(() {
      _saving = true;
      _amount = _cleanNumber(finalAmount);
      _pendingOperator = null;
      _storedValue = null;
      _startNewNumber = false;
    });

    try {
      final note = _noteController.text.trim();

      final transaction = TransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: note.isNotEmpty ? note : _category,
        category: _category,
        amount: finalAmount,
        isIncome: _type == 'Income',
        date: _selectedDate,
        accountId: _accountId,
        note: note.isNotEmpty ? note : null,
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_type saved successfully'),
          backgroundColor: darkGold,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('Unable to save transaction: $error');

      if (!mounted) return;

      _showMessage('Unable to save transaction. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildTypeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9DC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _typeTab('Income'),
          _typeTab('Expense'),
          _typeTab('Transfer'),
        ],
      ),
    );
  }

  Widget _typeTab(String type) {
    final selected = _type == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 5,
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: selected ? darkGold : muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      decoration: _boxDecoration(),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(
          color: textColor,
          fontSize: 13,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.edit_note_rounded,
            color: muted,
            size: 22,
          ),
          hintText: 'Add a note (optional)',
          hintStyle: TextStyle(
            color: muted,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildAccountRow() {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _accountsLoading ? null : _selectAccount,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dividerColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: darkGold,
                size: 21,
              ),
              const SizedBox(width: 10),
              const Text(
                'Account',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  _accountName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _accountId == null ? muted : textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              if (_accountsLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: gold,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Category',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: _manageCategories,
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: darkGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_categoriesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: gold,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_categories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dividerColor),
            ),
            child: const Text(
              'No categories available. Tap Manage to add one.',
              style: TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final selected = _category == category.name;

              return ChoiceChip(
                avatar: Icon(
                  category.icon,
                  size: 16,
                  color: selected ? darkGold : category.color,
                ),
                label: Text(category.name),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _category = category.name;
                  });
                },
                backgroundColor: cardColor,
                selectedColor: const Color(0xFFFFE9B4),
                side: BorderSide(
                  color: selected ? gold : dividerColor,
                ),
                labelStyle: TextStyle(
                  color: selected ? darkGold : textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            'AMOUNT',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _type == 'Income' ? '+' : '−',
                  style: TextStyle(
                    color: _activeColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '₹',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formattedAmount,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (_pendingOperator != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_cleanNumber(_storedValue ?? 0)} '
                  '$_pendingOperator ...',
              style: const TextStyle(
                color: muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    const keys = [
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '−'],
      ['.', '0', '⌫', '+'],
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: keys.map((row) {
          return Row(
            children: row.map((key) {
              final isOperator = ['÷', '×', '−'].contains(key);
              final isPlus = key == '+';
              final isDelete = key == '⌫';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    color: isPlus
                        ? gold
                        : isOperator
                        ? const Color(0xFFFFF0CD)
                        : background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _pressKey(key),
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 49,
                        child: Center(
                          child: isDelete
                              ? const Icon(
                            Icons.backspace_outlined,
                            color: darkGold,
                            size: 19,
                          )
                              : Text(
                            key,
                            style: TextStyle(
                              color: isPlus || isOperator
                                  ? darkGold
                                  : textColor,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRow() {
    final today =
    DateUtils.isSameDay(_selectedDate, DateTime.now());

    final time =
    TimeOfDay.fromDateTime(_selectedDate).format(context);

    final dateLabel = today
        ? 'Today'
        : '${_selectedDate.day} ${_monthName(_selectedDate.month)}';

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dividerColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: darkGold,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date and time',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateLabel, ${_selectedDate.day} '
                          '${_monthName(_selectedDate.month)} • $time',
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: darkGold,
          disabledBackgroundColor: gold.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _saving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: darkGold,
          ),
        )
            : Text(
          'Save $_type (₹$_formattedAmount)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: dividerColor),
    );
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),
        title: const Text(
          'Add Transaction',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _buildTypeTabs(),
            const SizedBox(height: 16),
            _buildNoteField(),
            const SizedBox(height: 12),
            _buildAccountRow(),
            const SizedBox(height: 18),
            _buildCategorySection(),
            const SizedBox(height: 18),
            _buildAmountCard(),
            const SizedBox(height: 12),
            _buildKeypad(),
            const SizedBox(height: 14),
            _buildDateRow(),
            const SizedBox(height: 18),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }
}