import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/category_service.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color secondaryText = Color(0xFF514939);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E1D4);

  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final NumberFormat _amountFormat = NumberFormat('#,##0.00');

  late DateTime _startDate;
  late DateTime _endDate;

  List<TransactionModel> _transactions = [];
  List<CategoryItem> _categories = [];

  bool _loading = true;
  bool _exportingCsv = false;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<TransactionModel> get _filteredTransactions {
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );

    final endExclusive = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
    ).add(const Duration(days: 1));

    return _transactions.where((transaction) {
      return !transaction.date.isBefore(start) &&
          transaction.date.isBefore(endExclusive);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> get _expenseTransactions =>
      _filteredTransactions.where((item) => !item.isIncome).toList();

  List<TransactionModel> get _incomeTransactions =>
      _filteredTransactions.where((item) => item.isIncome).toList();

  List<CategoryItem> _categoriesForType(bool isIncome) {
    final usedNames = <String>{};

    for (final transaction in _filteredTransactions) {
      if (transaction.isIncome == isIncome) {
        usedNames.add(transaction.category.trim().toLowerCase());
      }
    }

    return _categories.where((category) {
      return category.isIncome == isIncome &&
          usedNames.contains(category.name.trim().toLowerCase());
    }).toList()
      ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }

  int _categoryCount(bool isIncome) {
    return _filteredTransactions
        .where((transaction) => transaction.isIncome == isIncome)
        .map((transaction) => transaction.category.trim().toLowerCase())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _transactionService.getTransactions(),
        _categoryService.getCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _transactions = results[0] as List<TransactionModel>;
        _categories = results[1] as List<CategoryItem>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load transactions or categories.');
    }
  }

  Future<void> _refreshData() async {
    try {
      final results = await Future.wait([
        _transactionService.getTransactions(),
        _categoryService.getCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _transactions = results[0] as List<TransactionModel>;
        _categories = results[1] as List<CategoryItem>;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to refresh report data.');
      }
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Select start date' : 'Select end date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: gold,
              onPrimary: textColor,
              surface: background,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = selected;

        if (_startDate.isAfter(_endDate)) {
          _endDate = selected;
        }
      } else {
        _endDate = selected;

        if (_endDate.isBefore(_startDate)) {
          _startDate = selected;
        }
      }
    });
  }

  CategoryItem? _findCategory(String name, bool isIncome) {
    final normalizedName = name.trim().toLowerCase();

    for (final category in _categories) {
      if (category.isIncome == isIncome &&
          category.name.trim().toLowerCase() == normalizedName) {
        return category;
      }
    }

    return null;
  }

  String _displayCategory(String category) {
    final cleaned = category.trim();
    if (cleaned.isEmpty) return 'Uncategorized';

    return cleaned;
  }

  String _displayAccount(String? accountId) {
    final value = accountId?.trim();

    if (value == null || value.isEmpty) {
      return 'Not specified';
    }

    switch (value.toLowerCase()) {
      case 'card':
        return 'Card';
      case 'cash':
        return 'Cash';
      case 'savings':
        return 'Savings';
      default:
        return value
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map(
              (part) =>
          '${part[0].toUpperCase()}${part.substring(1)}',
        )
            .join(' ');
    }
  }

  String _formatAmount(double amount) => _amountFormat.format(amount);

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _exportCsv() async {
    if (_exportingCsv || _exportingPdf) return;

    setState(() => _exportingCsv = true);

    try {
      final rows = <List<String>>[
        [
          'Date & Time',
          'Type',
          'Amount',
          'Category',
          'Account Used',
        ],
      ];

      for (final transaction in _filteredTransactions) {
        rows.add([
          _dateTimeFormat.format(transaction.date),
          transaction.isIncome ? 'Income' : 'Expense',
          _formatAmount(transaction.amount),
          _displayCategory(transaction.category),
          _displayAccount(transaction.accountId),
        ]);
      }

      // UTF-8 BOM helps spreadsheet apps identify UTF-8 CSV correctly.
      final csv = '\uFEFF${rows.map((row) {
        return row.map(_csvCell).join(',');
      }).join('\r\n')}';

      final bytes = Uint8List.fromList(utf8.encode(csv));
      final filename =
          'DailyDhan_Report_${DateFormat('yyyyMMdd').format(_startDate)}'
          '_${DateFormat('yyyyMMdd').format(_endDate)}.csv';

      await SharePlus.instance.share(
        ShareParams(
          title: 'DailyDhan CSV Report',
          text: 'DailyDhan transaction report',
          files: [
            XFile.fromData(
              bytes,
              name: filename,
              mimeType: 'text/csv',
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to export CSV. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_exportingCsv || _exportingPdf) return;

    setState(() => _exportingPdf = true);

    try {
      final pdf = pw.Document();

      final expenses = _expenseTransactions;
      final incomes = _incomeTransactions;

      final expenseTotal = expenses.fold<double>(
        0,
            (sum, transaction) => sum + transaction.amount,
      );

      final incomeTotal = incomes.fold<double>(
        0,
            (sum, transaction) => sum + transaction.amount,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text(
              'DailyDhan - Export Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Date range: ${_dateFormat.format(_startDate)} - '
                  '${_dateFormat.format(_endDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromInt(0xFFE8E1D4),
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Export Summary',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Total records: ${_filteredTransactions.length}'),
                  pw.Text(
                    'Income records: ${incomes.length} '
                        'in ${_categoryCount(true)} categories',
                  ),
                  pw.Text(
                    'Expense records: ${expenses.length} '
                        'in ${_categoryCount(false)} categories',
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Total income: ${_formatAmount(incomeTotal)}'),
                  pw.Text('Total expenses: ${_formatAmount(expenseTotal)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Transactions',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (_filteredTransactions.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 18),
                child: pw.Text('No transactions in this date range.'),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Date & Time',
                  'Type',
                  'Amount',
                  'Category',
                  'Account Used',
                ],
                data: _filteredTransactions.map((transaction) {
                  return [
                    _dateTimeFormat.format(transaction.date),
                    transaction.isIncome ? 'Income' : 'Expense',
                    _formatAmount(transaction.amount),
                    _displayCategory(transaction.category),
                    _displayAccount(transaction.accountId),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                cellPadding: const pw.EdgeInsets.all(5),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5E8C7),
                ),
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFE8E1D4),
                  width: 0.5,
                ),
              ),
            pw.SizedBox(height: 16),

          ],
        ),
      );

      final filename =
          'DailyDhan_Report_${DateFormat('yyyyMMdd').format(_startDate)}'
          '_${DateFormat('yyyyMMdd').format(_endDate)}.pdf';

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: filename,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to export PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Export Report',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(color: gold),
        )
            : Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: gold,
                onRefresh: _refreshData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [
                    const Text(
                      'SELECT THE DATE RANGE YOU WANT TO EXPORT:',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateRangeCard(),
                    const SizedBox(height: 28),
                    const Text(
                      'EXPORT SUMMARY:',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: muted,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Exported files (.csv, .pdf) cannot be used '
                                'to restore data. They are not backup files.',
                            style: TextStyle(
                              color: muted,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _exportingCsv || _exportingPdf
                          ? null
                          : _exportCsv,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: textColor,
                        side: const BorderSide(color: dividerColor),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _exportingCsv
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: darkGold,
                        ),
                      )
                          : const Text(
                        'EXPORT CSV',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _exportingCsv || _exportingPdf
                          ? null
                          : _exportPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: textColor,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _exportingPdf
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: textColor,
                        ),
                      )
                          : const Text(
                        'EXPORT PDF',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D9B8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'From:',
              date: _startDate,
              onTap: () => _selectDate(isStart: true),
            ),
          ),
          Container(
            width: 1,
            height: 68,
            color: const Color(0xFFF0D9B8),
          ),
          Expanded(
            child: _buildDateButton(
              label: 'To:',
              date: _endDate,
              onTap: () => _selectDate(isStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _dateFormat.format(date).toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _filteredTransactions.length;
    final expenses = _expenseTransactions;
    final incomes = _incomeTransactions;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D9B8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Found a total of '),
                  TextSpan(
                    text: '$total records',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: ' within the selected date range.',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: dividerColor),
          _buildTransactionSummary(
            transactions: expenses,
            isIncome: false,
          ),
          const Divider(height: 1, color: dividerColor),
          _buildTransactionSummary(
            transactions: incomes,
            isIncome: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSummary({
    required List<TransactionModel> transactions,
    required bool isIncome,
  }) {
    final categories = _categoriesForType(isIncome);
    final categoryCount = _categoryCount(isIncome);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Text(
                  '•',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transactions.length} ${isIncome ? 'income' : 'expense'} '
                      'records in $categoryCount categories.',
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...categories.take(3).map(_buildCategoryIcon),
                  if (categories.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF3E4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF0D9B8)),
                      ),
                      child: Text(
                        '+${categories.length - 3} more',
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(CategoryItem category) {
    return Tooltip(
      message: category.name,
      child: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: category.color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          category.icon,
          color: Colors.white,
          size: 19,
        ),
      ),
    );
  }
}