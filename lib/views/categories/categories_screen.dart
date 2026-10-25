import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryItem {
  final String id;
  final String name;
  final String description;
  final bool isIncome;
  final int colorValue;
  final int iconCodePoint;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.isIncome,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);

  IconData get icon =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'isIncome': isIncome,
    'colorValue': colorValue,
    'iconCodePoint': iconCodePoint,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isIncome: json['isIncome'] as bool,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }
}

class CategoryService {
  static const String _storageKey = 'dailydhan_categories';

  static final List<CategoryItem> _defaults = [
    _make('Salary', 'Monthly salary', true, 0xFF24599B,
        Icons.account_balance_wallet_outlined),
    _make('Freelance', 'Freelance earnings', true, 0xFF14816D,
        Icons.work_outline_rounded),
    _make('Business', 'Business income', true, 0xFF71359A,
        Icons.store_outlined),
    _make('Investment', 'Investment returns', true, 0xFF536E20,
        Icons.trending_up_rounded),
    _make('Gift', 'Gifts and rewards', true, 0xFFD74432,
        Icons.card_giftcard_outlined),
    _make('Other', 'Other income', true, 0xFFD9AA2B,
        Icons.category_outlined),
    _make('Food', 'Groceries and dining', false, 0xFFD52A1C,
        Icons.restaurant_outlined),
    _make('Travel', 'Travel and transport', false, 0xFF2144AA,
        Icons.directions_bus_outlined),
    _make('Shopping', 'Shopping and lifestyle', false, 0xFF1872C8,
        Icons.shopping_bag_outlined),
    _make('Bills', 'Bills and utilities', false, 0xFF303944,
        Icons.receipt_long_outlined),
    _make('Health', 'Medical and healthcare', false, 0xFFE44B0B,
        Icons.favorite_border_rounded),
    _make('Other', 'Other expenses', false, 0xFF887D67,
        Icons.category_outlined),
  ];

  static CategoryItem _make(
      String name,
      String description,
      bool isIncome,
      int colorValue,
      IconData icon,
      ) {
    final prefix = isIncome ? 'income' : 'expense';
    final categoryName =
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    return CategoryItem(
      id: '${prefix}_$categoryName',
      name: name,
      description: description,
      isIncome: isIncome,
      colorValue: colorValue,
      iconCodePoint: icon.codePoint,
    );
  }

  Future<List<CategoryItem>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    if (saved == null) {
      final defaults = List<CategoryItem>.from(_defaults);
      await _save(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;

      return decoded
          .map(
            (item) => CategoryItem.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList();
    } catch (_) {
      final defaults = List<CategoryItem>.from(_defaults);
      await _save(defaults);
      return defaults;
    }
  }

  Future<void> addCategory(CategoryItem category) async {
    final categories = await getCategories();

    final exists = categories.any(
          (item) =>
      item.isIncome == category.isIncome &&
          item.name.trim().toLowerCase() ==
              category.name.trim().toLowerCase(),
    );

    if (exists) {
      throw Exception('Category already exists.');
    }

    categories.add(category);
    await _save(categories);
  }

  Future<void> updateCategory(CategoryItem updated) async {
    final categories = await getCategories();

    final exists = categories.any(
          (item) =>
      item.id != updated.id &&
          item.isIncome == updated.isIncome &&
          item.name.trim().toLowerCase() ==
              updated.name.trim().toLowerCase(),
    );

    if (exists) {
      throw Exception('Category already exists.');
    }

    final index =
    categories.indexWhere((item) => item.id == updated.id);

    if (index == -1) {
      throw Exception('Category not found.');
    }

    categories[index] = updated;
    await _save(categories);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    categories.removeWhere((item) => item.id == id);
    await _save(categories);
  }

  Future<void> _save(List<CategoryItem> categories) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(categories.map((item) => item.toJson()).toList()),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E1D4);

  final CategoryService _service = CategoryService();
  final TextEditingController _searchController =
  TextEditingController();

  List<CategoryItem> _categories = [];
  bool _loading = true;
  String _search = '';
  String _selectedType = 'Expense';

  List<CategoryItem> get _filteredCategories {
    final query = _search.trim().toLowerCase();

    return _categories.where((category) {
      final matchesType =
          category.isIncome == (_selectedType == 'Income');

      final matchesSearch = query.isEmpty ||
          category.name.toLowerCase().contains(query) ||
          category.description.toLowerCase().contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _service.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Unable to load categories.');
    }
  }

  Future<void> _refreshCategories() async {
    try {
      final categories = await _service.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to refresh categories.');
      }
    }
  }

  Future<void> _showCategoryDialog({CategoryItem? category}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CategoryDialog(
        category: category,
        initialIsIncome: _selectedType == 'Income',
        service: _service,
        onMessage: _showMessage,
      ),
    );

    if (!mounted || result != true) return;

    await _refreshCategories();

    if (!mounted) return;

    _showMessage(
      category == null
          ? 'Category added successfully.'
          : 'Category updated successfully.',
    );
  }

  Future<void> _deleteCategory(CategoryItem category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: background,
        title: const Text(
          'Delete category?',
          style: TextStyle(color: textColor),
        ),
        content: Text(
          'Remove "${category.name}" from your categories?',
          style: const TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _service.deleteCategory(category.id);
      await _refreshCategories();

      if (mounted) {
        _showMessage('Category deleted.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to delete category.');
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: muted),
      filled: true,
      fillColor: cardColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: textColor),
        ),
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            color: textColor,
            fontSize: 19,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _search = value),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: const TextStyle(
                    color: muted,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: muted,
                    size: 20,
                  ),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                    ),
                  ),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _typeTab('Expense'),
                    _typeTab('Income'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text(
                  'No categories found',
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                  ),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                    20, 0, 20, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _categoryTile(filtered[index]),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add New Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: textColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String type) {
    final selected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            type,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight:
              selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(CategoryItem category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category.description.isEmpty
                      ? (category.isIncome
                      ? 'Income category'
                      : 'Expense category')
                      : category.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: muted,
              size: 21,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showCategoryDialog(category: category);
              } else if (value == 'delete') {
                _deleteCategory(category);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final CategoryItem? category;
  final bool initialIsIncome;
  final CategoryService service;
  final ValueChanged<String> onMessage;

  const _CategoryDialog({
    required this.category,
    required this.initialIsIncome,
    required this.service,
    required this.onMessage,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8E1D4);

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late bool _isIncome;
  late int _selectedColor;
  late int _selectedIcon;
  bool _saving = false;

  static const List<Color> _colors = [
    Color(0xFFD74432),
    Color(0xFF14816D),
    Color(0xFF24599B),
    Color(0xFF71359A),
    Color(0xFFE36B12),
    Color(0xFF536E20),
    Color(0xFFD9AA2B),
    Color(0xFF303944),
  ];

  static const List<IconData> _icons = [
    Icons.category_outlined,
    Icons.restaurant_outlined,
    Icons.shopping_bag_outlined,
    Icons.home_outlined,
    Icons.directions_car_outlined,
    Icons.school_outlined,
    Icons.receipt_long_outlined,
    Icons.favorite_border_rounded,
    Icons.work_outline_rounded,
    Icons.card_giftcard_outlined,
    Icons.savings_outlined,
    Icons.devices_other_outlined,
  ];

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');

    _isIncome = widget.category?.isIncome ?? widget.initialIsIncome;
    _selectedColor =
        widget.category?.colorValue ?? gold.toARGB32();
    _selectedIcon =
        widget.category?.iconCodePoint ?? Icons.category_outlined.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: muted),
      filled: true,
      fillColor: cardColor,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      widget.onMessage('Enter a category name.');
      return;
    }

    setState(() => _saving = true);

    final category = widget.category;

    final item = CategoryItem(
      id: category?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      description: _descriptionController.text.trim(),
      isIncome: _isIncome,
      colorValue: _selectedColor,
      iconCodePoint: _selectedIcon,
    );

    try {
      if (category == null) {
        await widget.service.addCategory(item);
      } else {
        await widget.service.updateCategory(item);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      widget.onMessage(
        error.toString().contains('already exists')
            ? 'This category already exists.'
            : 'Unable to save category.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return AlertDialog(
      backgroundColor: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text(
        category == null ? 'Add New Category' : 'Edit Category',
        style: const TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category type',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Income'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Expense'),
                ),
              ],
              selected: {_isIncome},
              onSelectionChanged: _saving
                  ? null
                  : (selection) =>
                  setState(() => _isIncome = selection.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: gold,
                selectedForegroundColor: textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Description or tags'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose a color',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((color) {
                final selected = color.toARGB32() == _selectedColor;

                return GestureDetector(
                  onTap: _saving
                      ? null
                      : () => setState(
                        () => _selectedColor = color.toARGB32(),
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: textColor, width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an icon',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                final selected = icon.codePoint == _selectedIcon;

                return GestureDetector(
                  onTap: _saving
                      ? null
                      : () => setState(
                        () => _selectedIcon = icon.codePoint,
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? gold.withValues(alpha: 0.3)
                          : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? darkGold : dividerColor,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 21,
                      color: darkGold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
          _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: muted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: textColor,
          ),
          onPressed: _saving ? null : _saveCategory,
          child: _saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor,
            ),
          )
              : Text(category == null ? 'Add Category' : 'Save'),
        ),
      ],
    );
  }
}