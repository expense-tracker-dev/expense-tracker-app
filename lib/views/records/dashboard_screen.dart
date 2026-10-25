import 'package:flutter/material.dart';
import '../categories/categories_screen.dart';
import '../calculator/cash_calculator_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  static const Color gold = Color(0xFFD9AA2B);
  static const Color darkGold = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color muted = Color(0xFF887D67);
  static const Color cream = Color(0xFFFCF8EF);
  static const Color dividerColor = Color(0xFFE8E1D4);
  static const Color logoutBackground = Color(0xFFFFE9E6);
  static const Color logoutRed = Color(0xFFB42318);

  void _showMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be connected soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CategoriesScreen(),
      ),
    );
  }

  void _openCashCalculator(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const CashCalculatorScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 18),

                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Records',
                    selected: true,
                    onTap: onClose,
                  ),

                  const SizedBox(height: 5),

                  _buildMenuItem(
                    context,
                    icon: Icons.file_download_outlined,
                    title: 'Export Reports',
                    badge: 'New Tax Tools',
                    onTap: () => _showMessage(context, 'Export Reports'),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.call_split_rounded,
                    title: 'Split Dhan',
                    badge: '3 Active',
                    onTap: () => _showMessage(context, 'Split Dhan'),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: 'Money Forecast',
                    badge: '✦ AI',
                    onTap: () => _showMessage(context, 'Money Forecast'),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.calculate_outlined,
                    title: 'Cash Calculator',
                    onTap: () => _openCashCalculator(context),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: dividerColor,
                      height: 1,
                    ),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.category_outlined,
                    title: 'Manage Categories',
                    showArrow: true,
                    onTap: () => _openCategories(context),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'Help & Concierge',
                    showArrow: true,
                    onTap: () => _showMessage(context, 'Help & Concierge'),
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
      child: Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              color: darkGold,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'DailyDhan',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Material(
            color: cream,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                height: 36,
                width: 36,
                child: Icon(
                  Icons.close_rounded,
                  color: textColor,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9DFC9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: darkGold,
                  size: 30,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: Container(
                  height: 17,
                  width: 17,
                  decoration: const BoxDecoration(
                    color: darkGold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aarav Sharma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'aarav.sharma@gmail.com',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool selected = false,
        bool showArrow = false,
        String? badge,
      }) {
    return Material(
      color: selected ? gold : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          height: 49,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? darkGold : const Color(0xFF655A43),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.65)
                          : const Color(0xFFFFE4A3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (showArrow)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFC9BDA7),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            color: dividerColor,
            height: 1,
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: darkGold,
                size: 12,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'DailyDhan v2.4.1 • Private & Encrypted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5D513E),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: logoutBackground,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                onClose();
                _showMessage(context, 'Log Out');
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD8D3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: logoutRed,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: logoutRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Signs out on this device',
                            style: TextStyle(
                              color: logoutRed,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: logoutRed,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}