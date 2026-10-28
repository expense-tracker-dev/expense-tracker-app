import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/auth/auth_gate.dart';
import 'views/records/records_screen.dart';
import 'views/charts/charts_screen.dart';
import 'views/transactions/add_transaction_screen.dart';
import 'views/budgets/budgets_screen.dart';
import 'views/accounts/accounts_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: '.env');

  runApp(const DailyDhanApp());
}

class DailyDhanApp extends StatelessWidget {
  const DailyDhanApp({super.key});

  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyDhan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          primary: gold,
          secondary: darkGold,
          surface: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: textColor,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainNavigationScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const Color background = Color(0xFFFCF8EF);
  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color muted = Color(0xFF887D67);
  static const Color dividerColor = Color(0xFFE8E1D4);

  int _selectedIndex = 0;

  final GlobalKey<BudgetsScreenState> _budgetsKey =
  GlobalKey<BudgetsScreenState>();

  late final List<Widget> _screens = [
    const RecordsScreen(),
    const ChartsScreen(),
    const SizedBox.shrink(),
    BudgetsScreen(key: _budgetsKey),
    const AccountsScreen(),
  ];

  Future<void> _openAddTransaction() async {
    HapticFeedback.selectionClick();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _selectedIndex = 0;
    });

    if (result == true) {
      await _budgetsKey.currentState?.refreshData();
    }
  }

  void _onTabSelected(int index) {
    if (index == 2) {
      _openAddTransaction();
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      _budgetsKey.currentState?.refreshData();
    }
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        splashColor: gold.withValues(alpha: 0.10),
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 58,
          child: Transform.translate(
            offset: const Offset(0, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? gold : muted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? darkGold : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(
            color: dividerColor,
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _buildNavigationItem(
                index: 0,
                icon: Icons.receipt_long_rounded,
                label: 'Records',
              ),
              _buildNavigationItem(
                index: 1,
                icon: Icons.bar_chart_rounded,
                label: 'Charts',
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -5),
                    child: Material(
                      color: gold,
                      elevation: 4,
                      shadowColor: gold.withValues(alpha: 0.30),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _openAddTransaction,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.add_rounded,
                            color: darkGold,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildNavigationItem(
                index: 3,
                icon: Icons.account_balance_wallet_outlined,
                label: 'Budgets',
              ),
              _buildNavigationItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Accounts',
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}